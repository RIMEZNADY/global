package com.microgrid;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = {
    "com.microgrid",
    "com.microgrid.authentication",
    "com.microgrid.establishment"
})
@EnableScheduling
public class MicrogridBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicrogridBackendApplication.class, args);
    }
}

