package bingol.campus.mailservice;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "emailTaskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5); // Aynı anda çalışacak minimum thread sayısı
        executor.setMaxPoolSize(10); // Aynı anda çalışacak maksimum thread sayısı
        executor.setQueueCapacity(100); // Kuyruğa alınacak iş sayısı
        executor.setThreadNamePrefix("EmailThread-"); // Thread ismi prefixi
        executor.initialize();
        return executor;
    }
}
