package com.neubert.scaffold.motdservice;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;


@RestController
@RequestMapping("/motd")
public class MotdController {
  private static final Logger LOG = LoggerFactory.getLogger(MotdController.class);

  RestTemplate restTemplate;

  public MotdController(RestTemplate restTemplate) {
    this.restTemplate = restTemplate;
  }

  @GetMapping("/{name}")
  public String motd(@PathVariable("name") String name, HttpServletRequest request) {
    request.getHeaderNames().asIterator().forEachRemaining(s -> LOG.info("Header {}: {}", s, request.getHeader(s)));

    String hello = restTemplate.getForObject("http://hello-service:8080/hello/" + name.trim(), String.class);
    return "This is the message of the day: " + hello;
  }
}
