// Originally created by Mysterion_06_.
// Additional credits: 10_days_till_xmas, Ero, EvanMad, TheSast, Shoen, YellowSwerve
// Website: https://github.com/Mysterion06/Ultrakill

state("ULTRAKILL") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "ULTRAKILL";

    settings.Add("cpSplits", false, "Split whenever hitting a checkpoint");
    settings.Add("ilMode", false, "IL runs: split on specified amount of kills, reset on level restart");
    settings.SetToolTip(
        "ilMode",
        "Kill splits are defined by the segment name:" + "\n" +
        "  Use [##] anywhere in the segment name to define the kill count." + "\n" +
        "  Example: 'Level Name [10]' will split upon the 10th kill, only when on the split with that name.");

    settings.Add("cgMode", false, "CG runs: split on specified wave numbers (on the start of that wave), reset on run restart");
    settings.SetToolTip(
        "cgMode",
        "Wave splits are defined by the segment name:" + "\n" + 
        "  Use [##] anywhere in the segment name to define the wave to split that segment on." + "\n" +
        "  Example: 'Wave [30]' will split on the 1st frame that wave 30 begins, only when on that split.");

    vars.SegmentNumber = new Dictionary<int, int>();

    vars.Helper.AlertGameTime();
}

onStart
{
    vars.TotalGameTime = 0d;

    vars.SegmentNumber.Clear();
    for (int i = 0; i < timer.Run.Count; i++)
    {
        var segment = timer.Run[i];

        int start = segment.Name.IndexOf('[');
        if (start == -1) continue;

        int end = segment.Name.IndexOf(']', start);
        if (end == -1) continue;

        int segmentnum;
        if (int.TryParse(segment.Name.Substring(start + 1, end - start - 1), out segmentnum))
            vars.SegmentNumber[i] = segmentnum;
    }
}

init
{
    vars.TotalGameTime = 0d;

    vars.WaitForGameTime = false;

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var sm = mono.GetClass("StatsManager", 1);

        vars.Helper["Checkpoint"] = sm.Make<IntPtr>("instance", "currentCheckPoint");
        vars.Helper["Level"] = sm.Make<int>("instance", "levelNumber");
        vars.Helper["Kills"] = sm.Make<int>("instance", "kills");
        vars.Helper["Seconds"] = sm.Make<float>("instance", "seconds");
        vars.Helper["TimerRunning"] = sm.Make<bool>("instance", "timer");
        vars.Helper["LevelInProgress"] = sm.Make<bool>("instance", "timerOnOnce");
        vars.Helper["LevelEnd"] = sm.Make<bool>("instance", "infoSent");

        var eg = mono.GetClass("EndlessGrid", 1);

        vars.Helper["Wave"] = eg.Make<int>("instance","currentWave");

        return true;
    });
}

update
{
    if (old.TimerRunning && !current.TimerRunning)
    {
        current.TimerRunning = !vars.WaitForGameTime;
        vars.WaitForGameTime = !vars.WaitForGameTime;
    }
}

start
{
    return !old.LevelInProgress && current.LevelInProgress;
}

split
{
    if (settings["ilMode"])
    {
        int segmentnumber;
        if (vars.SegmentNumber.TryGetValue(timer.CurrentSplitIndex, out segmentnum)
            && current.Kills >= segmentnum)
        {
            return true;
        }
    }
    if (settings["cgMode"])
    {
        int segmentnum;
        if (vars.SegmentNumber.TryGetValue(timer.CurrentSplitIndex, out segmentnum)
            && current.Wave >= segmentnum)
        {
            return true;
        }
    }

    return (current.LevelEnd && !old.LevelEnd)
        || settings["cpSplits"] && old.Checkpoint != current.Checkpoint && current.Checkpoint != IntPtr.Zero;
}

reset
{
    return old.LevelInProgress && !current.LevelInProgress
        && (settings["ilMode"] || timer.CurrentSplitIndex == 0);
}

gameTime
{
    if (current.Seconds < old.Seconds){
        vars.TotalGameTime += old.Seconds;
    }

    if (current.TimerRunning)
        return TimeSpan.FromSeconds(vars.TotalGameTime + current.Seconds);
}

isLoading
{
    return true;
}
