using System.Drawing;
using System.Windows.Automation;
using System.Windows.Automation.Text;

namespace LayoutFixer;

/// The suggestion bubble next to the text cursor. It never takes focus and clicks pass through it.
sealed class Popup : Form
{
    readonly Label title = new(), hint = new();
    int generation;

    public Popup()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.FromArgb(0x1E, 0x23, 0x22);
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        Padding = new Padding(14, 10, 14, 10);

        title.AutoSize = true;
        title.ForeColor = Color.White;
        title.Font = new Font("Segoe UI Semibold", 13f);
        title.MaximumSize = new Size(520, 0);
        hint.AutoSize = true;
        hint.ForeColor = Color.FromArgb(0x9A, 0xA6, 0xA4);
        hint.Font = new Font("Segoe UI", 9f);
        hint.Margin = new Padding(0, 4, 0, 0);

        var stack = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, AutoSize = true, WrapContents = false, BackColor = BackColor };
        stack.Controls.Add(title);
        stack.Controls.Add(hint);
        Controls.Add(stack);
        // Create the window now (hidden): BeginInvoke only works once it exists, and the first
        // suggestion arrives from a background thread before the popup has ever been shown.
        _ = Handle;
    }

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            var cp = base.CreateParams;
            // No activation, no taskbar button, always on top, click-through.
            cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008 | 0x00000020;
            return cp;
        }
    }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        // Windows 11: rounded corners and a subtle mint border.
        int round = 2, border = 0x00D4EA5E & 0x00FFFFFF; // COLORREF is 0x00BBGGRR: #5EEAD4
        Native.DwmSetWindowAttribute(Handle, 33, ref round, sizeof(int));
        Native.DwmSetWindowAttribute(Handle, 34, ref border, sizeof(int));
    }

    public void ShowSuggestion(string suggestion, string target)
    {
        title.Text = suggestion;
        title.RightToLeft = suggestion.Any(c => c >= 0x0600 && c <= 0x06FF) ? RightToLeft.Yes : RightToLeft.No;
        hint.Text = $"Tab: fix & switch to {target}    ·    Esc: ignore";
        // Finding the caret can be slow in some apps, so do it off the UI thread.
        int gen = ++generation;
        Task.Run(Caret.Find).ContinueWith(t =>
        {
            if (gen != generation || IsDisposed) return;
            BeginInvoke(() => Place(t.Result));
        });
    }

    void Place(Rectangle? caret)
    {
        var anchor = caret ?? new Rectangle(Cursor.Position, Size.Empty);
        var screen = Screen.FromPoint(anchor.Location).WorkingArea;
        var size = PreferredSize;
        int x = Math.Clamp(anchor.Left, screen.Left + 4, screen.Right - size.Width - 4);
        int y = anchor.Bottom + 6;
        if (y + size.Height > screen.Bottom) y = anchor.Top - size.Height - 6;
        Location = new Point(x, y);
        if (!Visible) Show();
    }

    public void HideIt()
    {
        generation++;
        if (Visible) Hide();
    }
}

/// Where the text cursor is in the app you're typing in.
static class Caret
{
    public static Rectangle? Find()
    {
        // 1. The classic Win32 caret (Notepad, Office, most native apps).
        uint thread = Native.GetWindowThreadProcessId(Native.GetForegroundWindow(), out _);
        var info = new Native.GUITHREADINFO { cbSize = System.Runtime.InteropServices.Marshal.SizeOf<Native.GUITHREADINFO>() };
        if (Native.GetGUIThreadInfo(thread, ref info) && info.hwndCaret != IntPtr.Zero)
        {
            var p = new Native.POINT { X = info.rcCaret.Left, Y = info.rcCaret.Top };
            if (Native.ClientToScreen(info.hwndCaret, ref p))
                return new Rectangle(p.X, p.Y, Math.Max(1, info.rcCaret.Right - info.rcCaret.Left), Math.Max(1, info.rcCaret.Bottom - info.rcCaret.Top));
        }
        // 2. UI Automation (browsers, modern apps).
        try
        {
            var element = AutomationElement.FocusedElement;
            if (element?.TryGetCurrentPattern(TextPattern.Pattern, out var pattern) == true)
            {
                var selection = ((TextPattern)pattern).GetSelection();
                if (selection.Length > 0)
                {
                    var range = selection[0];
                    var rects = range.GetBoundingRectangles();
                    if (rects.Length == 0)
                    {
                        var wider = range.Clone();
                        wider.MoveEndpointByUnit(TextPatternRangeEndpoint.Start, TextUnit.Character, -1);
                        rects = wider.GetBoundingRectangles();
                    }
                    if (rects.Length > 0)
                    {
                        var r = rects[^1];
                        return new Rectangle((int)r.Right, (int)r.Top, 1, Math.Max(1, (int)r.Height));
                    }
                }
            }
        }
        catch { /* app doesn't support it */ }
        // 3. Fall back to the mouse pointer.
        return null;
    }
}
