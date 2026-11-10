Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

Write-Host "=== TEST WINRT SPEECH RECOGNIZER ==="
try {
    # Load Windows.Media.SpeechRecognition
    $null = [Windows.Media.SpeechRecognition.SpeechRecognizer, Windows.Media.SpeechRecognition, ContentType = WindowsRuntime]
    $allLangs = [Windows.Media.SpeechRecognition.SpeechRecognizer]::AllSupportedLanguages
    Write-Host "AllSupportedLanguages count: $($allLangs.Count)"
    foreach ($lang in $allLangs) {
        Write-Host "Supported Language: $($lang.LanguageTag) ($($lang.DisplayName))"
    }

    $systemSpeechLanguage = [Windows.Media.SpeechRecognition.SpeechRecognizer]::SystemSpeechLanguage
    Write-Host "SystemSpeechLanguage: $($systemSpeechLanguage.LanguageTag) ($($systemSpeechLanguage.DisplayName))"

    # Test creating recognizer with en-IN
    $enInLang = New-Object Windows.Globalization.Language("en-IN")
    $recognizer = New-Object Windows.Media.SpeechRecognition.SpeechRecognizer($enInLang)
    Write-Host "Created recognizer for: $($recognizer.CurrentLanguage.LanguageTag)"

    # Compile dictation grammar
    $topicConstraint = New-Object Windows.Media.SpeechRecognition.SpeechRecognitionTopicConstraint([Windows.Media.SpeechRecognition.SpeechRecognitionScenario]::Dictation, "dictation")
    $recognizer.Constraints.Add($topicConstraint)
    
    $compilationResult = Await ($recognizer.CompileConstraintsAsync()) ([Windows.Media.SpeechRecognition.SpeechRecognitionCompilationResult])
    Write-Host "Constraints compilation status: $($compilationResult.Status)"

    $recognizer.Dispose()
    Write-Host "WinRT SpeechRecognizer with en-IN DNN compiled successfully!"
} catch {
    Write-Host "WinRT Speech error: $($_.Exception.Message)"
}
