namespace LayoutFixer;

/// An installed keyboard layout we know how to fix between (English or Persian).
sealed record Layout(IntPtr Hkl, string Lang)
{
    public string DisplayName => Lang == "fa" ? "فارسی" : "English";

    /// The character this layout produces for a physical key.
    public string? Character(uint vk, uint scan, bool shift)
    {
        var keyState = new byte[256];
        if (shift) keyState[0x10] = 0x80;
        var buf = new char[8];
        // Flag 0x4: don't touch the keyboard's dead-key state while asking.
        int n = Native.ToUnicodeEx(vk, scan, keyState, buf, buf.Length, 0x4, Hkl);
        return n > 0 ? new string(buf, 0, n) : null;
    }
}

static class Layouts
{
    const int LangPersian = 0x29, LangEnglish = 0x09;

    static string? LangOf(IntPtr hkl)
    {
        int primary = (int)((long)hkl & 0x3FF);
        return primary == LangPersian ? "fa" : primary == LangEnglish ? "en" : null;
    }

    /// Installed English and Persian layouts, one per language.
    public static Dictionary<string, Layout> Enabled()
    {
        int n = Native.GetKeyboardLayoutList(0, null);
        var list = new IntPtr[n];
        Native.GetKeyboardLayoutList(n, list);
        var result = new Dictionary<string, Layout>();
        foreach (var hkl in list)
            if (LangOf(hkl) is { } lang && !result.ContainsKey(lang)) result[lang] = new Layout(hkl, lang);
        return result;
    }

    /// The layout of the window you're typing in.
    public static Layout? Current()
    {
        uint thread = Native.GetWindowThreadProcessId(Native.GetForegroundWindow(), out _);
        var hkl = Native.GetKeyboardLayout(thread);
        return LangOf(hkl) is { } lang ? new Layout(hkl, lang) : null;
    }

    public static Layout? Other(Layout current) => Enabled().Values.FirstOrDefault(l => l.Lang != current.Lang);
}
