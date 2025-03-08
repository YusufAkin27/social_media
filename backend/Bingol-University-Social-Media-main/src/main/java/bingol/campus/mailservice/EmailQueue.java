package bingol.campus.mailservice;

import java.util.concurrent.LinkedBlockingQueue;

public class EmailQueue {
    private final LinkedBlockingQueue<EmailMessage> queue = new LinkedBlockingQueue<>();

    public void enqueue(EmailMessage email) {
        if (email != null) {
            try {
                queue.put(email); // E-posta kuyruğa eklenir; bu metod kuyruk doluysa bekler
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt(); // Hata durumunda iş parçacığını kes
                System.out.println("E-posta kuyruğa eklenirken kesildi: " + e.getMessage());
            }
        }
    }

    public EmailMessage dequeue() throws InterruptedException {
        return queue.take();
    }

    public boolean isEmpty() {
        return queue.isEmpty();
    }

    public int size() {
        return queue.size();
    }

    public void clear() {
        queue.clear();
    }
}
