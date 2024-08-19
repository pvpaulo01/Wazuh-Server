#!/bin/bash

# Verifica se o usuário forneceu pelo menos dois argumentos
if [ "$#" -lt 2 ]; then
    echo "Uso: $0 arquivo1.evtx arquivo2.evtx ... arquivoN.evtx nome_do_arquivo.json"
    exit 1
fi

# Nome do arquivo de saída final é o último argumento
FINAL_JSON="${@: -1}"

# Lista de arquivos EVTX é todos os argumentos, exceto o último
EVTX_FILES=("${@:1:$#-1}")

# Limpar o arquivo final se já existir
> "$FINAL_JSON"

# Função para processar cada arquivo EVTX
process_evtx() {
    EVTX_FILE="$1"
    TEMP_JSON="temp.json"

    # Converter EVTX para JSON
    ./evtx_dump-v0.8.3-x86_64-unknown-linux-gnu -o json -f "$TEMP_JSON" "$EVTX_FILE"

    # Processar o JSON temporário e adicionar ao arquivo final
    python3 << EOF
import json

def rename_keys(obj):
    """
    Renomeia chaves '#attributes' para 'attributes' em um dicionário ou lista de dicionários.
    """
    if isinstance(obj, dict):
        new_obj = {}
        for key, value in obj.items():
            new_key = key.replace("#attributes", "attributes")
            new_obj[new_key] = rename_keys(value)
        return new_obj
    elif isinstance(obj, list):
        return [rename_keys(item) for item in obj]
    return obj

def process_json_file(input_file, output_file):
    json_objects = []
    current_json = ''

    with open(input_file, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.strip()
            if line.startswith('Record'):
                if current_json:
                    try:
                        json_object = json.loads(current_json)
                        json_object = rename_keys(json_object)
                        json_objects.append(json_object)
                    except json.JSONDecodeError as e:
                        print(f"Erro ao decodificar JSON: {e}")
                    current_json = ''
            else:
                current_json += line

        if current_json:
            try:
                json_object = json.loads(current_json)
                json_object = rename_keys(json_object)
                json_objects.append(json_object)
            except json.JSONDecodeError as e:
                print(f"Erro ao decodificar JSON: {e}")

    json_lines = [json.dumps(obj, separators=(',', ':')) for obj in json_objects]

    with open(output_file, 'a') as outfile:
        outfile.write('\n'.join(json_lines) + '\n')

    print(f"Adicionado ao arquivo tratado '{output_file}'")

# Caminho para o arquivo JSON de entrada e saída
input_file = '$TEMP_JSON'
output_file = '$FINAL_JSON'

process_json_file(input_file, output_file)
EOF

    # Remover o arquivo temporário
    rm "$TEMP_JSON"
}

# Iterar sobre todos os arquivos EVTX fornecidos
for EVTX_FILE in "${EVTX_FILES[@]}"; do
    process_evtx "$EVTX_FILE"
done

echo "Processo concluído. JSON final salvo em '$FINAL_JSON'."