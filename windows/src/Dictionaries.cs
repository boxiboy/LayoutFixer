using System.IO;
using System.Text;

namespace LayoutFixer;

/// Decides whether a word was typed on the wrong layout, in either direction.
/// A suggestion is only made when the other reading is a real word, so names, brands
/// and typos ("github", "teh") are left alone. Same rules as the Mac version.
sealed class Dictionaries
{
    readonly Dictionary<string, int> enRank, faRank;
    readonly HashSet<string> enAll;
    /// Only the most common Persian words count as a real reading; the long tail of the list is noisy.
    const int FaLimit = 30000;

    public Dictionaries(string directory)
    {
        enRank = Load(Path.Combine(directory, "en_50k.txt"));
        faRank = Load(Path.Combine(directory, "fa_50k.txt"));
        enAll = new HashSet<string>(enRank.Keys);
        var words = Path.Combine(directory, "words.txt");
        if (File.Exists(words))
            foreach (var line in File.ReadLines(words, Encoding.UTF8)) enAll.Add(line.Trim().ToLowerInvariant());
    }

    static Dictionary<string, int> Load(string path)
    {
        var ranks = new Dictionary<string, int>();
        if (!File.Exists(path)) return ranks;
        int i = 0;
        foreach (var line in File.ReadLines(path, Encoding.UTF8))
        {
            var word = line.Split(' ')[0];
            ranks.TryAdd(Normalize(word), i++);
        }
        return ranks;
    }

    public static string Normalize(string s)
    {
        s = s.ToLowerInvariant().Replace('ي', 'ی').Replace('ك', 'ک');
        int start = 0, end = s.Length;
        static bool Trim(char c) => char.IsPunctuation(c) || char.IsSymbol(c) || char.IsWhiteSpace(c);
        while (start < end && Trim(s[start])) start++;
        while (end > start && Trim(s[end - 1])) end--;
        return s[start..end];
    }

    int? PersianRank(string s) => faRank.TryGetValue(Normalize(s), out var r) && r < FaLimit ? r : null;

    /// True when the word was typed on the wrong layout.
    /// minLetters guards against short words, which are often ambiguous (شد is "an" on English keys).
    public bool IsMistake(string typed, string typedLang, string converted, int minLetters = 3)
    {
        if (typedLang == "fa")
        {
            // Typed on Persian keys: the English reading must be a common English word,
            // and more common than the Persian word itself if the typed text is real Persian.
            var english = Normalize(converted);
            if (english.Length < minLetters || !english.All(char.IsAscii) || !enRank.TryGetValue(english, out var en)) return false;
            return PersianRank(typed) is not { } fa || en < fa;
        }
        // Typed on English keys: never touch a real English word, and only suggest Persian when the
        // Persian reading is a real Persian word. ", ; ' [ ]" are Persian letters on English keys.
        var word = Normalize(typed);
        const string persianKeys = ",;'[]";
        if (word.Length < minLetters || !word.All(c => char.IsLetter(c) || persianKeys.Contains(c))
            || !word.Any(char.IsLetter) || enAll.Contains(word)) return false;
        // don't, it's, ...
        if (word.Contains('\'') && enAll.Contains(word.Split('\'')[0])) return false;
        return PersianRank(converted) is not null;
    }
}
