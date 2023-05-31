@echo off

mkdir "%userprofile%/Documents/Teardown/mods/TearHook"
xcopy /c /y /e . "%userprofile%/Documents/Teardown/mods/TearHook"
cd "%userprofile%/Documents/Teardown/mods/TearHook"
rmdir /s /q media
del pack.cmd
