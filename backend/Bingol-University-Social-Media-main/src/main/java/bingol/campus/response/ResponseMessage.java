       package bingol.campus.response;
       
       import lombok.AllArgsConstructor;
       import lombok.Data;
       
       @Data
       @AllArgsConstructor
       public class ResponseMessage {
              private String message;
              private boolean isSuccess;
       }
