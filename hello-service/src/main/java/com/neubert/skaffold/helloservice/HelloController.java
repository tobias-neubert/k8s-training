package com.neubert.skaffold.helloservice;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.ZoneOffset;


@RestController
@RequestMapping("/hello")
public class HelloController {
  private static final Logger LOG = LoggerFactory.getLogger(HelloController.class);
  private final boolean polite;

  public HelloController(@Value("${com.neubert.hello.polite:false}") boolean polite) {
    this.polite = polite;
  }

  @GetMapping("/{name}")
  public String hello(@PathVariable("name") String name, HttpServletRequest request) {
    request.getHeaderNames().asIterator().forEachRemaining(s -> LOG.info("Header {}: {}", s, request.getHeader(s)));

    if (polite) {
      return greetingOfTheDay() + " " + name;
    }

    return "Hello " + name;
  }

  private String greetingOfTheDay() {
    int hour = Instant.now().atZone(ZoneOffset.UTC).getHour();

    if (hour > 0 && hour < 12) {
      return "Good morning";
    }
    if (hour >= 12 && hour < 18) {
      return "Good day";
    }

    return "Good evening";
  }
}
