package bingol.campus.chatbot.controller;

import bingol.campus.chatbot.manager.ChatBotService;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/api/chatbot")
@RequiredArgsConstructor
public class ChatBotController {

    private final ChatBotService chatBotService;

    @GetMapping("/sendMessage")
    public String sendMessage(@AuthenticationPrincipal UserDetails userDetails, @RequestParam("message") String message) throws StudentNotFoundException {
        return chatBotService.sendMessage(userDetails.getUsername(),message);
    }
}

