package com.microgrid.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

/**
 * Configuration pour RestTemplate utilisé pour appeler le microservice AI
 */
@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        
        // Configuration du timeout
        ClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        ((SimpleClientHttpRequestFactory) factory).setConnectTimeout(5000);
        ((SimpleClientHttpRequestFactory) factory).setReadTimeout(10000);
        restTemplate.setRequestFactory(factory);
        
        return restTemplate;
    }
}


