package com.prj4devops;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@RestController
public class SampleController {

    @RequestMapping("/")
    public String hello(HttpServletRequest request){
        String result = "src: "+request.getRemoteAddr()+" / dest: "+request.getServerName()+"\n";
        return result;
    }
}
