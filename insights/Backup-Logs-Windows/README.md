# Injetando Logs EVTX no Wazuh

## Informações Importantes

A ferramenta Wazuh não suporta a importação direta de arquivos `.evtx` criados pelo Windows. Não é possível configurar o apontamento desses arquivos diretamente nos agentes clientes. Portanto, é necessário converter os eventos EVTX para JSON e, em seguida, injetá-los no Wazuh, caso seja necessário.

A estrutura de logs permitida pelo Wazuh para indexação e exibição nos alertas é bastante específica. No entanto, o script shell localizado neste repositório já formata os logs corretamente. Agora, basta fazer o apontamento no Filebeat.

Vou guiá-los para superar esse desafio, então vamos juntos!

## Passos para Injetar Logs EVTX

### 1. Baixe o Programa `evtx_dump`

Primeiro, baixe o programa `evtx_dump` para converter os arquivos EVTX em JSON:

```
wget https://github.com/omerbenamram/evtx/releases/download/v0.8.3/evtx_dump-v0.8.3-x86_64-unknown-linux-gnu
```
### 2. Permissões e Conversão

Dê permissão de execução ao programa:

```
# chmod +x evtx_dump-v0.8.3-x86_64-unknown-linux-gnu
```

O repositório acima orienta sobre a sintaxe correta para a conversão de arquivos EVTX para JSON.

### 3. Manipulação do Arquivo JSON
Agora, crie um script Python para manipular o arquivo JSON e ajustá-lo ao formato suportado pelo Wazuh. Caso o script shell presente neste repositório (convert.sh) atenda às suas necessidades, você pode usá-lo.

### 4. Apontamento no Filebeat
Após converter o arquivo, basta fazer o apontamento para que o Filebeat possa criar os índices correspondentes às datas reais dos logs.

Adicione o caminho do arquivo convertido em /usr/share/filebeat/module/alerts/manifest.yml.
Se seu arquivo json estiver em /var/log/logs-evtx.json o conteudo do arquivo manifest.yml ficaria:
```
filebeat.modules:
  - module: wazuh
    alerts:
      enabled: true
      input:
        paths:
          - /var/ossec/logs/alerts/alerts.json
          - /var/log/logs-evtx.json
```
### 5. Reinicie o Filebeat
Reinicie o Filebeat para que as alterações tenham efeito:
```
# systemctl restart filebeat
```
Após reiniciar, verifique se os logs estão sendo exibidos corretamente na interface web do Wazuh.
