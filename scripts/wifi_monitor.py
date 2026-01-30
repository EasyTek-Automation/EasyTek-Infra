import subprocess
import time
import urllib.request
import logging
from datetime import datetime
import os

# Configurar logging no diretório do usuário
log_path = os.path.join(os.path.expanduser('~'), 'wifi_monitor.log')
logging.basicConfig(
    filename=log_path,
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

def verificar_internet(timeout=5):
    """Verifica se há conexão com a internet"""
    try:
        urllib.request.urlopen('http://www.google.com', timeout=timeout)
        return True
    except:
        return False

def obter_nome_wifi():
    """Obtém o nome da rede WiFi conectada"""
    try:
        resultado = subprocess.check_output(
            ['netsh', 'wlan', 'show', 'interfaces'],
            shell=True,
            encoding='cp850',
            errors='ignore'
        )
        
        for linha in resultado.split('\n'):
            if 'SSID' in linha and 'BSSID' not in linha:
                return linha.split(':')[1].strip()
    except:
        return None

def desconectar_wifi():
    """Desconecta o WiFi"""
    try:
        subprocess.run(
            ['netsh', 'wlan', 'disconnect'],
            shell=True,
            check=True,
            capture_output=True
        )
        logging.info("WiFi desconectado")
        return True
    except:
        logging.error("Erro ao desconectar WiFi")
        return False

def conectar_wifi(nome_rede):
    """Conecta ao WiFi"""
    try:
        subprocess.run(
            ['netsh', 'wlan', 'connect', f'name={nome_rede}'],
            shell=True,
            check=True,
            capture_output=True
        )
        logging.info(f"Tentando reconectar ao WiFi: {nome_rede}")
        return True
    except:
        logging.error(f"Erro ao conectar ao WiFi: {nome_rede}")
        return False

def monitorar_conexao(intervalo=30):
    """Monitora a conexão e reconecta se necessário"""
    logging.info("Monitor iniciado")
    
    falhas_consecutivas = 0
    
    while True:
        try:
            if verificar_internet():
                if falhas_consecutivas > 0:
                    logging.info("Conexão restabelecida")
                falhas_consecutivas = 0
            else:
                falhas_consecutivas += 1
                logging.warning(f"Sem conexão à internet (falha {falhas_consecutivas})")
                
                # Só reconecta após 2 falhas consecutivas
                if falhas_consecutivas >= 2:
                    nome_rede = obter_nome_wifi()
                    
                    if nome_rede:
                        logging.info(f"Tentando reconectar ao WiFi: {nome_rede}")
                        desconectar_wifi()
                        time.sleep(3)
                        conectar_wifi(nome_rede)
                        time.sleep(10)
                        falhas_consecutivas = 0
                    else:
                        logging.error("Não foi possível identificar a rede WiFi")
            
            time.sleep(intervalo)
            
        except Exception as e:
            logging.error(f"Erro no monitoramento: {str(e)}")
            time.sleep(intervalo)

if __name__ == "__main__":
    monitorar_conexao(intervalo=30)