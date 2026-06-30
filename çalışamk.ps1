(Get-Content "source\mobile\psychlua\Functions.hx") `
  -replace 'mobileControls\.buttonExtra2', '(cast MusicBeatState.getState().mobileControls : mobile.objects.IMobileControls).buttonExtra2' `
  -replace 'mobileControls\.buttonExtra\b', '(cast MusicBeatState.getState().mobileControls : mobile.objects.IMobileControls).buttonExtra' |
  Set-Content "source\mobile\psychlua\Functions.hx"