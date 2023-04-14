@echo off
chcp 1252

rem Cria o arquivo datas.txt caso ele não exista
if not exist datas.txt (
    echo O arquivo datas.txt não existe. Criando novo arquivo vazio.
    type nul > datas.txt
)

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
    echo.
    del novas_datas.txt > nul
    pause
    goto :eof
)

rem Pergunta ao usuário se deseja atualizar as datas
set /p resposta="As datas são diferentes. Deseja atualizar o arquivo datas.txt? (S/N): "

if /i "%resposta%"=="s" (
    rem Substitui o arquivo datas.txt pelas novas datas
    echo.
    echo Atualizando o arquivo datas.txt...
    move /y novas_datas.txt datas.txt > nul
    echo.
    color 4
    echo Arquivo datas.txt atualizado.
    echo.
    powershell -c "[console]::beep(500,300)"
    pause
) else (
    echo.
    echo Operação cancelada pelo usuário.
    echo.
    del novas_datas.txt > nul
    pause
)

goto :eof