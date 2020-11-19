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





E, abaixo, o código que dispara dados para a [API](#api)

**Coloque as informações corretas dos pinos de cada sensor e as informações de conexão.**
```
#include <stdio.h>
#include <stdbool.h>
#include <ultrasonic.h>

#include <string.h>
#include <sys/param.h>
#include <stdlib.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_event.h"
#include "esp_wifi.h"
#include "protocol_examples_common.h"
#include "nvs.h"
#include "nvs_flash.h"

#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include <lwip/netdb.h>
#include "driver/gpio.h"

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

#define PORT CONFIG_EXAMPLE_PORT

static const char *TAG = "";
QueueHandle_t buffer;
static EventGroupHandle_t s_wifi_event_group;
static int s_retry_num = 0;

static void event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data) {

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
		if(DEBUG)
		    ESP_LOGI(TAG, "Tentando conectar ao WiFi...\r\n");
		/*
			O WiFi do ESP8266 foi configurado com sucesso. 
			Agora precisamos conectar a rede WiFi local. Portanto, foi chamado a função esp_wifi_connect();
		*/
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTING_BIT);

        xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
        xEventGroupClearBits(s_wifi_event_group, WIFI_FAIL_BIT);

        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < EXAMPLE_ESP_MAXIMUM_RETRY) {
			/*
			Se chegou aqui foi devido a falha de conexão com a rede WiFi.
			Por esse motivo, haverá uma nova tentativa de conexão WiFi pelo ESP8266.
			*/
            xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTING_BIT);

            xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
            xEventGroupClearBits(s_wifi_event_group, WIFI_FAIL_BIT);

            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGW(TAG, "Tentando reconectar ao WiFi...");
        } else {
			/*
				É necessário apagar o bit para avisar as demais Tasks que a 
				conexão WiFi está offline no momento. 
			*/
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);

            xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
            xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTING_BIT);

            ESP_LOGE(TAG,"Falha ao conectar ao WiFi");
        }
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
		/*
			Conexão efetuada com sucesso. Busca e imprime o IP atribuido. 
		*/
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Conectado! O IP atribuido é:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
		/*
				Seta o bit indicativo para avisar as demais Tasks que o WiFi foi conectado. 
		*/
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);

        xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTING_BIT);
        xEventGroupClearBits(s_wifi_event_group, WIFI_FAIL_BIT);
    }

}

 /* Inicializa o WiFi em modo cliente (Station) */
void wifi_init_sta(void) {

    s_wifi_event_group = xEventGroupCreate(); //Cria o grupo de eventos
    xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTING_BIT);
    tcpip_adapter_init();

    ESP_ERROR_CHECK(esp_event_loop_create_default());

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = EXAMPLE_ESP_WIFI_SSID,
            .password = EXAMPLE_ESP_WIFI_PASS
        },
    };

    /* Setting a password implies station will connect to all security modes including WEP/WPA.
        * However these modes are deprecated and not advisable to be used. Incase your Access point
        * doesn't support WPA2, these mode can be enabled by commenting below line */

    if (strlen((char *)wifi_config.sta.password)) {
        wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
    }

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "wifi_init_sta finished.");

}

/* Tarefas (Tasks) */
void task_botao(void *pvParameter) {

    gpio_set_direction(BUTTON, GPIO_MODE_INPUT);
	gpio_set_pull_mode(BUTTON, GPIO_PULLUP_ONLY);  

    while (TRUE) {   
        xEventGroupWaitBits(s_wifi_event_group, WIFI_FAIL_BIT, pdFALSE, pdFALSE, portMAX_DELAY);	
        
        if (!gpio_get_level(BUTTON)) {	
			vTaskDelay( 50/portTICK_PERIOD_MS );
            s_retry_num = 0;
            esp_wifi_connect();

		}
		vTaskDelay(100/portTICK_PERIOD_MS);
    }

}

void task_led(void *pvParameter) {

    int ledDelay = 500;
    bool ledFlag = 0;

	gpio_set_direction(LED_BUILDING, GPIO_MODE_OUTPUT);	
	
    while (TRUE) {    
        EventBits_t bits = xEventGroupGetBits(s_wifi_event_group);
        if (bits & WIFI_CONNECTING_BIT) {

            ledDelay = 500;

            gpio_set_level(LED_BUILDING, ledFlag);

            ledFlag = !ledFlag;

        } else if(bits & WIFI_CONNECTED_BIT) {

            gpio_set_level(LED_BUILDING, 0);

        } else if(bits & WIFI_FAIL_BIT) {

            ledDelay = 100;

            gpio_set_level(LED_BUILDING, ledFlag);

            ledFlag = !ledFlag;

        }
		vTaskDelay(ledDelay/portTICK_PERIOD_MS);
    }

}

static void task_wifi(void *pvParameters) {

    char rx_buffer[128];
    char addr_str[128];
    int addr_family;
    int ip_protocol;

    while (1) {

#ifdef CONFIG_EXAMPLE_IPV4
        struct sockaddr_in destAddr;
        destAddr.sin_addr.s_addr = htonl(INADDR_ANY);
        destAddr.sin_family = AF_INET;
        destAddr.sin_port = htons(PORT);
        addr_family = AF_INET;
        ip_protocol = IPPROTO_IP;
        inet_ntoa_r(destAddr.sin_addr, addr_str, sizeof(addr_str) - 1);
#else // IPV6
        struct sockaddr_in6 destAddr;
        bzero(&destAddr.sin6_addr.un, sizeof(destAddr.sin6_addr.un));
        destAddr.sin6_family = AF_INET6;
        destAddr.sin6_port = htons(PORT);
        addr_family = AF_INET6;
        ip_protocol = IPPROTO_IPV6;
        inet6_ntoa_r(destAddr.sin6_addr, addr_str, sizeof(addr_str) - 1);
#endif

        int listen_sock = socket(addr_family, SOCK_STREAM, ip_protocol);
        if (listen_sock < 0) {
            ESP_LOGE(TAG, "Não foi possível criar o socket, erro: errno %d", errno);
            break;
        }
        ESP_LOGI(TAG, "Socket foi criado com sucesso.");

        int err = bind(listen_sock, (struct sockaddr *)&destAddr, sizeof(destAddr));
        if (err != 0) {
            ESP_LOGE(TAG, "Não foi capaz de vincular o socket, erro: errno %d", errno);
            break;
        }
        ESP_LOGI(TAG, "Socket foi vinculado.");

        err = listen(listen_sock, 1);
        if (err != 0) {
            ESP_LOGE(TAG, "Problema detectado enquanto escutava o socket, erro: errno %d", errno);
            break;
        }
        ESP_LOGI(TAG, "Socket esperando conexão..."); 

#ifdef CONFIG_EXAMPLE_IPV6
        struct sockaddr_in6 sourceAddr; // Large enough for both IPv4 or IPv6
#else
        struct sockaddr_in sourceAddr;
#endif
        uint addrLen = sizeof(sourceAddr);
        int sock = accept(listen_sock, (struct sockaddr *)&sourceAddr, &addrLen);
        if (sock < 0) {
            ESP_LOGE(TAG, "Não foi possível realizar a conexão, erro: errno %d", errno);
            break;
        } else {
            ESP_LOGI(TAG, "Conexão Aceita.");
        }        
        while (1) {
            int len = recv(sock, rx_buffer, sizeof(rx_buffer) - 1, 0);
            if (len < 0) {
                ESP_LOGE(TAG, "Falha no recv, erro: errno %d", errno);
                break;
            } else if (len == 0) {
                ESP_LOGE(TAG, "Conexão encerrada.");
                break;
            } else {
#ifdef CONFIG_EXAMPLE_IPV6
                // Get the sender's ip address as string
                if (sourceAddr.sin6_family == PF_INET) {
                    inet_ntoa_r(((struct sockaddr_in *)&sourceAddr)->sin_addr.s_addr, addr_str, sizeof(addr_str) - 1);
                } else if (sourceAddr.sin6_family == PF_INET6) {
                    inet6_ntoa_r(sourceAddr.sin6_addr, addr_str, sizeof(addr_str) - 1);
                }
#else
                inet_ntoa_r(((struct sockaddr_in *)&sourceAddr)->sin_addr.s_addr, addr_str, sizeof(addr_str) - 1);
#endif

                rx_buffer[len] = 0; 

                ESP_LOGI(TAG, "Recebeu %d bytes de %s:", len, addr_str);
                ESP_LOGI(TAG, "%s", rx_buffer);

                ultrasonic_sensor_t sensor = {
                    .trigger_pin = TRIGGER_GPIO,
                    .echo_pin = ECHO_GPIO
                };

                ultrasonic_init(&sensor);

                if (len == 4 && rx_buffer[0] == 'D' && rx_buffer[1] == 'I' && rx_buffer[2] == 'S' && rx_buffer[3] == 'T') {
                    uint32_t distance;
                    esp_err_t res = ultrasonic_measure_cm(&sensor, MAX_DISTANCE_CM, &distance);

                    if (res != ESP_OK) {
                        switch (res) {
                            case ESP_ERR_ULTRASONIC_PING:
                                printf("Erro ping\n");
                                break;
                            case ESP_ERR_ULTRASONIC_PING_TIMEOUT:
                                printf("Erro timeout ping\n");
                                break;
                            case ESP_ERR_ULTRASONIC_ECHO_TIMEOUT:
                                printf("Erro echo ping\n");
                                break;
                            default:
                                printf("%d\n", res);
                        }
                    } else {
                        char integer_string[32];
                        sprintf(integer_string, "[Sensor]Distância: %d cm", distance);

                        int err = send(sock, strcat(integer_string,"\r\n"), strlen(strcat(integer_string,"\r\n")), 0);
                        if (err < 0) {
                            ESP_LOGE(TAG, "Error occured during sending: errno %d", errno);
                            break;
                        } else{
                            ESP_LOGE("Queue", "Item nao recebido, timeout expirou!");//Se o timeout expirou, mostra erro
                            break;
                        }
                    } 
                } else {
                    int err = send(sock, "Comando inexistente, utilize 'DIST' \r\n", strlen("Comando inexistente, utilize 'DIST' \r\n"), 0);
                    
                    if (err < 0) {
                        ESP_LOGE(TAG, "Error occured during sending: errno %d", errno);
                        break;
                    }
                }

                vTaskDelay(2000 / portTICK_PERIOD_MS);

            }
        }
    }
    vTaskDelete(NULL);

}

void app_main() {

    esp_err_t ret = nvs_flash_init();

    if (ret == ESP_ERR_NVS_NO_FREE_PAGES) {
      ESP_ERROR_CHECK(nvs_flash_erase());
      ret = nvs_flash_init();
    }

    ESP_ERROR_CHECK(ret);
    ESP_LOGI(TAG, "ESP_WIFI_MODE_STA");

    wifi_init_sta();

    if(xTaskCreate(task_led, "task_led", 2048, NULL, 1, NULL)!= pdTRUE) {
		if(DEBUG)
			ESP_LOGI(TAG, "Não foi possível alocar a task do LED.\n");	
		return;		
	}

    if (xTaskCreate(task_botao, "task_botao", 2048, NULL, 1, NULL) != pdTRUE) {
		if(DEBUG)
			ESP_LOGI(TAG, "Não foi possível alocar a task do botão. \n");	
		return;		
	}

    if (xTaskCreate(task_wifi, "task_wifi", 4096, NULL, 5, NULL) != pdTRUE) {
        if (DEBUG) 
            ESP_LOGI(TAG, "Não foi possível alocar a task de wifi. \n");
        return;
    }

}
```
### **Como iniciar a aplicação**

Para iniciar a aplicação, utilize:
```
start:dev
```


## **Aplicação**
O projeto foi desenvolvido na linguagem de programação [C](https://devdocs.io/c/), utilizando uma placa [Wemos D1](https://docs.wemos.cc/en/latest/d1/d1_mini.html)



### **Foto da aplicação web**
<img alt="GoStack" style="width:32%" src="https://media.discordapp.net/attachments/767426969851527188/779057517099089930/terminal.jpg" />


## **Licença**

Esse projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

Feito pelos alunos Bruno Silva Daniel e Thiago Rossi Spíndola da turma 2020/2 da disciplina de IOT II da faculdade SATC, dirigida por Vagner da Silva Rodrigues.
