@echo off
chcp 65001
set atualizacao=NAO
rem Cria o arquivo datas.txt caso ele não exista
if not exist datas.txt (
    echo O arquivo datas.txt não existe. Criando novo arquivo vazio.
    type nul > datas.txt
)

:verificar_datas
rem Obtém as datas dos estabelecimentos
echo.
echo Obtendo as datas dos estabelecimentos...
powershell -Command "Invoke-WebRequest -Uri https://dadosabertos.rfb.gov.br/CNPJ/ | Select-String -Pattern 'Estabelecimentos.*?([0-9]{4}-[0-9]{2}-[0-9]{2})' | ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique" > novas_datas.txt
echo.

rem Compara as novas datas com as armazenadas no arquivo datas.txt
echo.
echo Comparando as datas dos estabelecimentos...
fc /b novas_datas.txt datas.txt > nul
if not errorlevel 1 (
    echo Não foi necessário atualizar pois as datas são as mesmas.
    echo.
    color 9
    echo As datas são as mesmas.
	set "atualizacao= Não, as datas são as mesmas."
    echo.
	del novas_datas.txt > nul
    goto esperar
)

rem Pergunta ao usuário se deseja atualizar as datas
echo.
powershell -c "[console]::beep(500,500)"
set /p "input=As datas são diferentes. Deseja atualizar? (S/N) "
timeout /t 1 > nul
if /i "%input%"=="s" (
    rem Substitui o arquivo datas.txt pelas novas datas
    echo.
    echo Atualizando o arquivo datas.txt...
    move /y novas_datas.txt datas.txt > nul
    echo.
    color 4
    echo Arquivo datas.txt atualizado.
    echo.
	set "atualizacao=SIM, as datas foram atualizadas em:\n%data_atual% %hora_atual%."
    powershell -c "[console]::beep(500,300)"
) else (
    echo.
    echo Não foi feita nenhuma atualização.
    echo.
    del novas_datas.txt > nul
)

:esperar
rem Aguarda 15 minutos antes de verificar as datas novamente
setlocal enabledelayedexpansion
set /a "espera=15*60"
for /l %%i in (%espera%,-1,0) do (
    set /a "minutos=%%i/60, segundos=%%i%%60"
    echo Próxima verificação em !minutos! minutos e !segundos! segundos.
	echo Atualização: %atualizacao%
    timeout 1 >nul
    cls
)
endlocal
goto verificar_datas
