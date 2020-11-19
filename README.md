<p align="center">
 <img alt="GoStack" src="https://lh6.googleusercontent.com/proxy/K5fmOf83OCmcXLL6A8C661JiY_kCgEehnEzR8zyhludeemsL9n4R3vq1Q2aQBN_Vvd1PucGHzvY21aQNl_mvkhHDVNTAeFlgTLxVWaAQ4_eX" />
<p/><br/>

## **Sumário**

- [Introdução](#Introdução)
- [Script](#script)
- [Aplicação](#Aplicação)

## **Introdução**

 Desenvolver uma aplicação capaz de fazer a leitura de sensores de presença e fazer a comunicação entre um terminal externo via wifi atreves da criação de uma socket TCP, sendo capaz de visualizar as informações repassadas no terminal de acesso, o projeto tambem tem na protoboard um led de status sobre o atual estado do wifi e um botão para dar reboot na conexão, a, esse projeto é uma junção de todas as atividades ja feitas 

## **Script**
Os componentes que foram utilizados para a montagem foram:
- WeMos D1
- Sensor ultrassônico HC - SR04
- Push button
- Resistor (12kΩ)
- Jumpers

### Foto da montagem na prática e no TinkerCad
<br>
<p align="center">
 <img  alt="GoStack" style="width:47.3%" src="https://media.discordapp.net/attachments/767426969851527188/779052502405742673/wenos-on.jpg?width=506&height=677" />
 <img align="center" alt="GoStack" style="width:50%" src="https://media.discordapp.net/attachments/767426969851527188/779052231168622632/wenos.jpg" />
<p/>







**Congiguração das pinagens da Aplicação**
```

/* Definições e Constantes */
#define TRUE  1
#define FALSE 0
#define DEBUG TRUE 
#define LED_BUILDING	GPIO_NUM_2 //D4
#define BUTTON			GPIO_NUM_14  //D5
#define GPIO_INPUT_PIN_SEL  	(1ULL<<BUTTON)

#define EXAMPLE_ESP_WIFI_SSID      CONFIG_EXAMPLE_WIFI_SSID
#define EXAMPLE_ESP_WIFI_PASS      CONFIG_EXAMPLE_WIFI_PASSWORD
#define EXAMPLE_ESP_MAXIMUM_RETRY  5

#define WIFI_CONNECTED_BIT      BIT0
#define WIFI_FAIL_BIT           BIT1
#define WIFI_CONNECTING_BIT     BIT2

#define MAX_DISTANCE_CM 500
#define TRIGGER_GPIO 0 //D3
#define ECHO_GPIO 4 //D2


```
### **Como iniciar a aplicação**

Para configurar a aplicação atravez do terminal do mingw32, utilize:
```
make config
```

Para iniciar a aplicação atravez do terminal do mingw32, utilize:
```
make -j5 flash monitor
```



## **Aplicação**
O projeto foi desenvolvido na linguagem de programação [C](https://devdocs.io/c/), utilizando uma placa [Wemos D1](https://docs.wemos.cc/en/latest/d1/d1_mini.html)



### **Foto da aplicação**
<p align="center">
	<img alt="GoStack" style="width:32%" src="https://media.discordapp.net/attachments/767426969851527188/779057517099089930/terminal.jpg" />
<p/>

### **Video Youtube**

[![Web-socket](http://img.youtube.com/vi/4GfKDHFkdDU/0.jpg)](http://www.youtube.com/watch?v=4GfKDHFkdDU "https://cdn.discordapp.com/attachments/767426969851527188/779052231168622632/wenos.jpg")



## **Licença**

Esse projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

Feito pelos alunos Bruno Silva Daniel e Thiago Rossi Spíndola da turma 2020/2 da disciplina de IOT II da faculdade SATC, dirigida por Vagner da Silva Rodrigues.
