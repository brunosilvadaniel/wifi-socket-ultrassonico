

Sumário


Introdução
Script
API
Aplicação Web


Introdução

Desenvolver um hub para armazenar dados coletados de uma placa arduino conectado com módulo wi-fi, a partir dos dados coletados exibir em uma aplicação web afim de obter a variação dos dados conforme a localização geográfica do aparelho. Um exemplo seria coletar a temperatura de varias cidades.

Script

Os componentes que foram utilizados para a montagem foram:

Arduino Uno
Modelo WiFi - ESP8266
Sensor de temperatura DHT11
Sensor ultrassônico HC-SR04
Resistor 220 Ω
Jumper à gosto



Foto da montagem na prática e no TinkerCad



E, abaixo, o código que dispara dados para a API
Coloque as informações corretas dos pinos de cada sensor e as informações de conexão.
#include <SoftwareSerial.h>
#include "DHT.h"

#define PIN_DHT A0
#define DHTTYPE DHT11
#define PIN_SERIAL_TX 12
#define PIN_SERIAL_RX 11
#define PIN_SERIAL_LDR A5

#define KEY "{CHAVE NA API}"
#define LATITUDE "{LATITUDE}"
#define LONGITUDE "{LONGITUDE}"
#define USUARIO_WIFI "{USUARIO}"
#define SENHA_WIFI "{SENHA}"

SoftwareSerial esp8266(PIN_SERIAL_TX, PIN_SERIAL_RX);
DHT dht(PIN_DHT, DHTTYPE);

void setup() {
  Serial.begin(9600);
  dht.begin();
  esp8266.begin(9600);
  pinMode(PIN_SERIAL_LDR, INPUT);
  delay(1000);
  sendData("AT+RST\r\n", 5000, true);
  sendData("AT+CWJAP=\"" + String(USUARIO_WIFI) + "\",\"" + String(SENHA_WIFI) + "\"\r\n", 3000, true);
  delay(3000);
  sendData("AT+CWMODE=1\r\n", 1000, true);
  sendData("AT+CIFSR\r\n", 1000, true);
}

void loop() {
  float umidade = dht.readHumidity();
  float temperatura = dht.readTemperature();
  float luminosidade = analogRead(PIN_SERIAL_LDR);

  String url = "GET /api/v1/temperature/" + String(KEY) + "/";
  url += String(LATITUDE) + "/" + String(LONGITUDE) + "/" + String(temperatura) + "/" + String(umidade) + "/" + String(luminosidade);
  url += " HTTP/1.1\r\nHost: hub-temperature-iot.herokuapp.com\r\n";

  sendData("AT+CIPSTART=\"TCP\",\"hub-temperature-iot.herokuapp.com\",80\r\n", 500, true);
  sendData("AT+CIPSEND=" + String(url.length() + 4) + "\r\n", 500, true);
  sendData(url + "\r\n\r\n", 1000, true);
  sendData("AT+CIPCLOSE=0\r\n", 5000, true);
  delay(20000);
}

String sendData(String command, const int timeout, boolean debug) {
  String response = "";
  esp8266.print(command);
  long int time = millis();
  while ((time + timeout) > millis())
  {
    while (esp8266.available())
    {
      char c = esp8266.read();
      response += c;
    }
  }
  if (debug)
  {
    Serial.print(response);
  }
  return response;
}

API

Interpretador utilizado:

Node.js

Banco de dados utlizado:

MongoDB

Framework utilizado:

Express

Bibliotecas utlizadas:

Moment.js
uuid
Mongoose

Através da API, os aplicativos podem se comunicar uns com os outros sem conhecimento ou intervenção dos usuários. Elas funcionam através da comunicação de diversos códigos, definindo comportamentos específicos de determinado objeto em uma interface.

Heroku

O servidor para a API foi hospedado na Heroku. Resumidamente, O Heroku é uma das melhores e mais populares opções de plataforma como serviço Paas, ela suporta várias aplicações em diversas linguagens, dentre elas o NodeJS. Existem planos gratuitos e alguns pagos.
Caso queria saber como hospedar uma aplicação Node.js na Heroku, clique aqui

Como iniciar a API

Para iniciar a aplicação, utilize:
start:dev
Você pode começar os testes usando o exemplo de script e carregando-o no seu Arduino. Basicamente, a API consiste em 4 rotas que podem ser consultadas com auxilio do api-docs:
Para a visualização da documentação utilize:
npm run docs
Este comando irá criar uma pasta chamada docs, onde é criado uma página web com a documentação.

Aplicação Web

Feita em Reactjs e estilizada usando a biblioteca Material-UI
Reactjs é uma biblioteca JavaScript para criação de interfaces para o usuário, desenvolvida e mantida pelo Facebook, sua primeira release saiu em 2013. É  uma lib open-source com mais de 1k de colaboradores ativos no GitHub.
Para iniciar a aplicação, utilize o código:
npm install
E, após instalar todas as dependências, utilize:
npm start

Foto da aplicação web



Licença

Esse projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

Feito pela turma 2020/1 da disciplina de IOT II da faculdade SATC, dirigida por Vagner da Silva Rodrigues.
