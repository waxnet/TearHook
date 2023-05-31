@echo off

mkdir "%userprofile%/Documents/Teardown/mods/TearHook"
xcopy /c /y /e . "%userprofile%/Documents/Teardown/mods/TearHook"
cd "%userprofile%/Documents/Teardown/mods/TearHook"
del pack.cmd
