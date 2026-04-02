package com.fengpt.fengpt;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;

@SpringBootApplication(exclude = {
        DataSourceAutoConfiguration.class,
        HibernateJpaAutoConfiguration.class
})
public class Application {

    public static void main(String[] args) {
        /*System.setProperty("SERVICE_NAME","fengpt-pet");
        System.setProperty("APP_VERSION","v1");
        System.setProperty("LOG_FILE","/Users/work/test2/log");*/
        SpringApplication.run(Application.class, args);
    }
}

