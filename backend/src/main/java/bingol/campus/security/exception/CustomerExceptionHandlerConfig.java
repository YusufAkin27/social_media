package bingol.campus.security.exception;


import bingol.campus.response.ResponseMessage;

import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class CustomerExceptionHandlerConfig extends Throwable {

    @ExceptionHandler(value = BusinessException.class)
    public ResponseMessage businessExceptionHandler(BusinessException businessException) {
        return new ResponseMessage(businessException.getMessage(), false);
    }

}