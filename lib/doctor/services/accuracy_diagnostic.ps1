Add-Type -AssemblyName System.Speech

$source = @"
using System;
using System.Globalization;
using System.Speech.Recognition;
using System.Threading;

public class AccuracyDiagnosticRunner
{
    public static void RunDiagnostic()
    {
        Console.WriteLine("=== RECOGNIZER ENUMERATION ===");
        var recognizers = SpeechRecognitionEngine.InstalledRecognizers();
        RecognizerInfo selectedRecognizer = null;
        foreach (var r in recognizers)
        {
            Console.WriteLine("Found: " + r.Culture.Name + " - " + r.Name + " (ID: " + r.Id + ")");
            if (r.Culture.Name == "en-US" || r.Culture.Name.StartsWith("en"))
            {
                if (selectedRecognizer == null) selectedRecognizer = r;
            }
        }

        if (selectedRecognizer == null && recognizers.Count > 0)
        {
            selectedRecognizer = recognizers[0];
        }

        if (selectedRecognizer == null)
        {
            Console.WriteLine("ERROR: No Speech Recognition Engine installed on this system.");
            return;
        }

        Console.WriteLine("SELECTED: " + selectedRecognizer.Name + " (" + selectedRecognizer.Culture.Name + ")");

        // Ensure Thread culture matches selected recognizer culture
        Thread.CurrentThread.CurrentCulture = selectedRecognizer.Culture;
        Thread.CurrentThread.CurrentUICulture = selectedRecognizer.Culture;

        using (var engine = new SpeechRecognitionEngine(selectedRecognizer))
        {
            try
            {
                engine.SetInputToDefaultAudioDevice();
                Console.WriteLine("AUDIO INPUT: Default Audio Device Connected (Format: " + (engine.AudioFormat != null ? engine.AudioFormat.EncodingFormat.ToString() : "Default") + ")");
            }
            catch (Exception ex)
            {
                Console.WriteLine("ERROR: Cannot access audio device: " + ex.Message);
                return;
            }

            var dictation = new DictationGrammar();
            dictation.Name = "DefaultDictation";
            dictation.Weight = 1.0f;
            dictation.Priority = 0;
            engine.LoadGrammar(dictation);

            engine.SpeechHypothesized += (s, e) =>
            {
                if (e != null && e.Result != null)
                {
                    Console.WriteLine("[HYPOTHESIS] (" + e.Result.Confidence.ToString("F2") + ") " + e.Result.Text);
                }
            };

            engine.SpeechRecognized += (s, e) =>
            {
                if (e != null && e.Result != null)
                {
                    Console.WriteLine("------------------------------------------");
                    Console.WriteLine("[RECOGNIZED] (" + e.Result.Confidence.ToString("F2") + ") " + e.Result.Text);
                    Console.WriteLine("Words: ");
                    foreach (var w in e.Result.Words)
                    {
                        Console.WriteLine("  - " + w.Text + " [conf: " + w.Confidence.ToString("F2") + "]");
                    }
                    if (e.Result.Alternates.Count > 1)
                    {
                        Console.WriteLine("Alternates:");
                        for (int i = 1; i < Math.Min(4, e.Result.Alternates.Count); i++)
                        {
                            Console.WriteLine("  [" + i + "] (" + e.Result.Alternates[i].Confidence.ToString("F2") + ") " + e.Result.Alternates[i].Text);
                        }
                    }
                    Console.WriteLine("------------------------------------------");
                }
            };

            engine.SpeechRecognitionRejected += (s, e) =>
            {
                if (e != null && e.Result != null)
                {
                    Console.WriteLine("[REJECTED] (" + e.Result.Confidence.ToString("F2") + ") " + e.Result.Text);
                }
                else
                {
                    Console.WriteLine("[REJECTED] Unknown noise / audio");
                }
            };

            engine.AudioLevelUpdated += (s, e) =>
            {
                // periodic audio level check
            };

            engine.RecognizeAsync(RecognizeMode.Multiple);
            Console.WriteLine("READY_FOR_SPEECH: Listening now... Speak a phrase.");

            // Wait for 10 seconds of listening
            Thread.Sleep(10000);

            engine.RecognizeAsyncStop();
            Console.WriteLine("DIAGNOSTIC_COMPLETED");
        }
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Speech"
[AccuracyDiagnosticRunner]::RunDiagnostic()
