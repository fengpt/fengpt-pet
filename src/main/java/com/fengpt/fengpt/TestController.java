package com.fengpt.fengpt;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Slf4j
public class TestController {

    @Value("${fengpt}")
    private String dataTest;

    @GetMapping("/test")
    public String test(){
        log.info("test param{}",dataTest);
        return dataTest;
    }
}
