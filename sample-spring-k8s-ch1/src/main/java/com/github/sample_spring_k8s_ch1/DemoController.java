package com.github.sample_spring_k8s_ch1;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/hello")
public class DemoController {

    @Value("${custom.property}")
    private String customProperty;

    @GetMapping
    public String hello() {
        return "hello world from spring boot";
    }

    @GetMapping("/custom")
    public String custom() {
        return customProperty;
    }
}
