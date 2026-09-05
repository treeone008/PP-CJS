package com.example.demo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/payment")
public class PaymentController {
    @Autowired
    private PaymentRepository paymentRepository;

    @PostMapping
    public Payment createPayment(@RequestBody Payment payment) {
        payment.setStatus("COMPLETED");
        return paymentRepository.save(payment); // DB에 Insert
    }

    @GetMapping
    public List<Payment> getPayments() {
        return paymentRepository.findAll(); // DB에서 Select
    }

    @GetMapping("/health")
    public String health() {
        return "✅ PayGuard 결제 API 정상 동작 & DB 연결 완료!";
    }
}
