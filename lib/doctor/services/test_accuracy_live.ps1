Add-Type -AssemblyName System.Speech

$source = @"
using System;
using System.Globalization;
using System.Speech.Recognition;
using System.Threading;

public class LiveAccuracyTester
{
    public static void Main()
    {
        Console.WriteLine("[DIAGNOSTIC] Initializing SpeechRecognitionEngine with explicit Culture...");
        
        // Find best available English recognizer
        RecognizerInfo bestRecognizer = null;
        foreach (var r in SpeechRecognitionEngine.InstalledRecognizers())
        {
            Console.WriteLine("[DIAGNOSTIC] Available Recognizer: " + r.Culture.Name + " - " + r.Name);
            if (r.Culture.Name == "en-US" || r.Culture.Name == "en-IN" || r.Culture.Name.StartsWith("en"))
            {
                bestRecognizer = r;
                break;
            }
        }

        if (bestRecognizer == null)
        {
            Console.WriteLine("[ERROR] No English speech recognizer found.");
            return;
        }

        Console.WriteLine("[DIAGNOSTIC] Selected Recognizer: " + bestRecognizer.Name + " (" + bestRecognizer.Culture.Name + ")");

        // Synchronize thread culture to recognizer culture
        Thread.CurrentThread.CurrentCulture = bestRecognizer.Culture;
        Thread.CurrentThread.CurrentUICulture = bestRecognizer.Culture;

        using (var engine = new SpeechRecognitionEngine(bestRecognizer))
        {
            engine.SetInputToDefaultAudioDevice();
            
            // Configure dictation grammar
            var grammar = new DictationGrammar("grammar:dictation");
            grammar.Name = "Dictation";
            grammar.Weight = 1.0f;
            grammar.Priority = 0;
            engine.LoadGrammar(grammar);

            // Configure silence timeouts for natural speech pauses
            engine.InitialSilenceTimeout = TimeSpan.FromSeconds(6);
            engine.BabbleTimeout = TimeSpan.FromSeconds(0);
            engine.EndSilenceTimeout = TimeSpan.FromMilliseconds(500);
            engine.EndSilenceTimeoutAmbiguous = TimeSpan.FromMilliseconds(500);

            engine.SpeechHypothesized += (s, e) =>
            {
                if (e != null && e.Result != null && !string.IsNullOrWhiteSpace(e.Result.Text))
                {
                    Console.WriteLine("PARTIAL:" + e.Result.Text);
                }
            };

            engine.SpeechRecognized += (s, e) =>
            {
                if (e != null && e.Result != null && !string.IsNullOrWhiteSpace(e.Result.Text))
                {
                    Console.WriteLine("FINAL:" + e.Result.Text + " (Conf: " + e.Result.Confidence.ToString("F2") + ")");
                }
            };

            engine.SpeechRecognitionRejected += (s, e) =>
            {
                if (e != null && e.Result != null && !string.IsNullOrWhiteSpace(e.Result.Text))
                {
                    Console.WriteLine("REJECTED:" + e.Result.Text + " (Conf: " + e.Result.Confidence.ToString("F2") + ")");
                }
            };

            engine.RecognizeAsync(RecognizeMode.Multiple);
            Console.WriteLine("READY");

            // Wait for 15 seconds
            Thread.Sleep(15000);

            engine.RecognizeAsyncStop();
            Console.WriteLine("STOPPED");
        }
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Speech"
[LiveAccuracyTester]::Main()
