package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthCheckController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/health")
    public String healthCheck() {
        try {
            // DB가 정상적으로 연결되어 있는지 확인하는 가장 가벼운 쿼리
            jdbcTemplate.execute("SELECT 1");
            return "✅ PayGuard API is RUNNING & DB Connected!";
        } catch (Exception e) {
            return "❌ DB Connection FAILED: " + e.getMessage();
        }
    }
}
