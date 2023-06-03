@echo off

mkdir "%userprofile%/Documents/Teardown/mods/TearHook"
xcopy /c /y /e . "%userprofile%/Documents/Teardown/mods/TearHook"

cd "%userprofile%/Documents/Teardown/mods/TearHook"
rmdir /s /q .github
rmdir /s /q media
del reminder.txt
del README.md
del pack.cmd
del LICENSE
