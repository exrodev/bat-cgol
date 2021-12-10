@echo off
setlocal enableDelayedExpansion enableExtensions

:: Thanks you to 'figboot' - Gave me the idea to make the grid wrap. (not implemented yet)
::
:: RESOURCES:
::  - https://www.conwaylife.com/wiki/Conway%27s_Game_of_Life
::  - https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
::  - https://gamedevelopment.tutsplus.com/tutorials/creating-life-conways-game-of-life--gamedev-558

:: If you would like to play around with the shapes and stuff like that, the variables you would like to change would be:
::
:: GAME_AREA_X - The amount of columns the board has
:: GAME_AREA_Y - The amount of rows the board has
:: All of the calls to the cell function on lines 52+

title Conway's Game of Life - Batch Edition ^| by git.io/exrodev

cls

:: Set game variables
set GAME_AREA_X=10
set GAME_AREA_Y=10

set GAME_GENERATION=0

set /a AREA_X_t1=%GAME_AREA_X% - 1
set /a AREA_Y_t1=%GAME_AREA_Y% - 1
set /a AREA_X_p1=%GAME_AREA_X% + 1
set /a AREA_Y_p1=%GAME_AREA_Y% + 1
set /a AREA_Y_p2=%GAME_AREA_Y% + 2

:: Game logic
::  - A live cell with 0-1 neighbor dies (under population)
::  - A live cell with 2-3 neighbors lives to next generation
::  - A live cell with 4+ neighbors dies (over crowding)
::  - A dead cell with 3 neightbors will come alive (reproduction)

:: Creating the grid
for /l %%x in (0,1,%GAME_AREA_X%) do (
    for /l %%y in (0,1,%GAME_AREA_Y%) do (
        call :cell %%x %%y
    )
)

:: OBJECT DATA (by default, this is a glider)
:: I am planning to add a pattern loader where you can supply this data and the size of the game area.
::
:: To use the cell function, use 'call :cell <x position> <y position> [anything here will make it alive]'
:: If nothing is supplied for the last argument, then it will be a dead cell.
:: Anything that is surrounded by '<>' is a required argument.
call :cell 3 1 1
call :cell 3 2 1
call :cell 3 3 1
call :cell 2 3 1
call :cell 1 2 1

cls

call :border

:: Our lovely main loop/function
:main

if "%GAME_GENERATION%"=="0" (
    call :render
    set /a GAME_GENERATION+=1
    goto main
)


for /l %%x in (0,1,%GAME_AREA_X%) do (
    for /l %%y in (0,1,%GAME_AREA_Y%) do (
        set living=!cell[%%x,%%y]!
        call :getLivingNeighbors %%x %%y
        set neighbors=!LIVING_NEIGHBORS_OUTPUT!
        :: This result determines whether the cell will be dead or not (0 = dead, 1 = alive)
        set result=0

        if "!living!"=="1" (
            if !count! LSS 2 set result=0
            if !count! EQU 2 set result=1
            if !count! EQU 3 set result=1
            if !count! GTR 3 set result=0
        ) else (
            if !count! EQU 3 set result=1
        )

        set nextState[%%x,%%y]=!result!
    )
)

call :nextGameState
call :render

set /a GAME_GENERATION+=1

goto main



:: Create cell function
:: call :cell <x> <y> [anything = alive]
:cell
set pos_x=%~1
set pos_y=%~2
set alive=%~3

if "%pos_y%"=="" (
    echo [1;1f[31mERROR: [91mCreating cell - x='%pos_x%', y='%pos_y%'[0m
    exit /b 0
)

if "%alive%"=="" (
    set "cell[%pos_x%,%pos_y%]=0"
    set "nextState[%pos_x%,%pos_y%]=0"
) else (
    set "cell[%pos_x%,%pos_y%]=1"
    set "nextState[%pos_x%,%pos_y%]=1"
)
echo [1;1fCreated Cell: x=%pos_x% ^| y=%pos_y%
goto :eof


:: Gets the living neighbors for a certain cell and sets the output to 'LIVING_NEIGHBORS_OUTPUT'
:getLivingNeighbors <position-x> <position-y>
set pos_x=%~1
set pos_y=%~2

if "%pos_y%"=="" (
    echo [1;1f[31mERROR: [91mGetting neighbors - x='%pos_x%', y='%pos_y%'[0m
    exit /b 0
)

set count=0

set /a pos_x_t1=%pos_x%-1
set /a pos_x_p1=%pos_x%+1
set /a pos_y_t1=%pos_y%-1
set /a pos_y_p1=%pos_y%+1

if "%pos_x%" NEQ "%AREA_X_t1%" (
    if "!cell[%pos_x_p1%,%pos_y%]!"=="1" set /a count+=1
    if "%pos_y%" NEQ "%AREA_Y_t1%" (
        if "!cell[%pos_x_p1%,%pos_y_p1%]!"=="1" set /a count+=1
    )
)

if "%pos_y%" NEQ "%AREA_X_t1%" (
    if "!cell[%pos_x%,%pos_y_p1%]!"=="1" set /a count+=1
    if "%pos_x%" NEQ "0" (
        if "!cell[%pos_x_t1%,%pos_y_p1%]!"=="1" set /a count+=1
    )
)

if "%pos_x%" NEQ "0" (
    if "!cell[%pos_x_t1%,%pos_y%]!"=="1" set /a count+=1
    if "%pos_y%" NEQ "0" (
        if "!cell[%pos_x_t1%,%pos_y_t1%]!"=="1" set /a count+=1
    )
)

if "%pos_y%" NEQ "0" (
    if "!cell[%pos_x%,%pos_y_t1%]!"=="1" set /a count+=1
    if "%pos_x%" NEQ "%AREA_X_t1%" (
        if "!cell[%pos_x_p1%,%pos_y_t1%]!"=="1" set /a count+=1
    )
)

set LIVING_NEIGHBORS_OUTPUT=!count!
goto :eof

:nextGameState
for /l %%x in (0,1,%GAME_AREA_X%) do (
    for /l %%y in (0,1,%GAME_AREA_Y%) do (
        set cell[%%x,%%y]=!nextState[%%x,%%y]!
    )
)
goto :eof


:: Render function (this can be improved later so it only needs to update cells that need to be updated)
:render
set "line=[1;1f"

for /l %%y in (1,1,%GAME_AREA_Y%) do (
    set /a yt1=%%y - 1
    for /l %%x in (1,1,%GAME_AREA_X%) do (
        set /a xt1=%%x - 1
        if "!cell[%%x,%%y]!"=="1" (set "line=!line!#") else (set "line=!line! ")
    )
    set "line=!line![1E"
)
echo !line![1;1f
echo [%AREA_Y_p2%;1fGeneration: %GAME_GENERATION%

goto :eof


:: Border function (puts the border around the playing area)
:border

for /l %%x in (0,1,%AREA_X_p1%) do (
    echo [%AREA_Y_p1%;%%xf.
)
for /l %%y in (0,1,%AREA_Y_p1%) do (
    echo [%%y;%AREA_X_p1%f.
)

goto :eof
