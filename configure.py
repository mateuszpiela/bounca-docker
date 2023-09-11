#!/usr/bin/python

import yaml,os
from secrets import token_hex


def getOSEnv(envVarName, fallback):
    envVarValue = os.getenv(envVarName)
    if envVarValue is None or len(envVarValue) == 0:
        return fallback
    return envVarValue

def checkIfSecretRequiresToChange(yamlData):
    if yamlData is None or yamlData == "<value-django-secret-just-a-random-salt-string>" or len(yamlData) == 0:
        return token_hex(32)
    return yamlData
        

with open("/etc/bounca/services.yaml") as config:
    y = yaml.safe_load(config)
    y['psql']['dbname'] = getOSEnv("DB_NAME", "bounca")
    y['psql']['username'] = getOSEnv("DB_USER", "bounca")
    y['psql']['password'] = getOSEnv("DB_PASSWORD", "")
    y['psql']['host'] = getOSEnv("DB_HOST", "localhost")
    y['psql']['port'] = getOSEnv("DB_PORT", 5432)
    y['mail']['host'] = getOSEnv("MAIL_HOST", "localhost")
    y['mail']['port'] = getOSEnv("MAIL_PORT", 25)
    y['mail']['username'] = getOSEnv("MAIL_USER", "")
    y['mail']['password'] = getOSEnv("MAIL_PASSWORD", "")
    y['mail']['connection'] = getOSEnv("MAIL_CONNECTION", "none")
    y['mail']['admin'] = getOSEnv("MAIL_ADMIN", "admin@example.com")
    y['mail']['from'] = getOSEnv("MAIL_FROM", "no-reply@example.com")
    y['django']['secret_key'] = checkIfSecretRequiresToChange(y['django']['secret_key'])
    y['django']['hosts'] = list()
    y['django']['hosts'].append(getOSEnv("DOMAIN", ""))
    y['certificate-engine']['key_algorithm'] = getOSEnv("CE_KEY_ALGO", "rsa")
    y['registration']['email_verification'] = getOSEnv("EMAIL_VERIFICATION", "off")

    with open("/etc/bounca/services.yaml", "w") as config_rw:
        yaml.dump(y, config_rw)
        
