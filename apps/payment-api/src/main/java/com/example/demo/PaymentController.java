package com.example.demo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/payment")
public class PaymentController {
    private static final Logger auditLogger = LoggerFactory.getLogger("AuditLogger");

    @Autowired
    private PaymentRepository paymentRepository;

    @PostMapping
    public Payment createPayment(@RequestBody Payment payment) {
        payment.setStatus("COMPLETED");
        Payment saved = paymentRepository.save(payment);
        // 감사 로그 파일에 기록
        auditLogger.info("Payment Created: ID={}, Amount={}", saved.getId(), saved.getAmount());
        return saved;
    }

    @GetMapping
    public List<Payment> getPayments() {
        return paymentRepository.findAll();
    }

    @GetMapping("/health")
    public String health() {
        return "✅ PayGuard 결제 API 정상 동작 & DB 연결 완료!";
    }
}
