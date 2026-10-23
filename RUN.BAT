@echo off
rem EIN. MEER. VON. SAND. -- starts DOSBox with DOSBOX.CONF from this folder
cd /d "%~dp0"
where dosbox >nul 2>nul && (dosbox -conf DOSBOX.CONF & goto :eof)
if exist "%ProgramFiles(x86)%\DOSBox-0.74-3\DOSBox.exe" ("%ProgramFiles(x86)%\DOSBox-0.74-3\DOSBox.exe" -conf DOSBOX.CONF & goto :eof)
if exist "%ProgramFiles%\DOSBox-0.74-3\DOSBox.exe" ("%ProgramFiles%\DOSBox-0.74-3\DOSBox.exe" -conf DOSBOX.CONF & goto :eof)
if exist "%ProgramFiles%\DOSBox-X\dosbox-x.exe" ("%ProgramFiles%\DOSBox-X\dosbox-x.exe" -conf DOSBOX.CONF & goto :eof)
echo DOSBox was not found. Start DOSBox and type:  mount c "%~dp0"  then  c:  then  sand
pause
