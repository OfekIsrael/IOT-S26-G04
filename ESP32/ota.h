#pragma once

#include "SECRETS.h"
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <Update.h>

namespace ota {

    const char* serverIndex =
        "<script src='https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js'></script>"
        "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;'>"

        "<h2>OTA Update & Diagnostics</h2>"

        "<form method='POST' action='#' enctype='multipart/form-data' id='upload_form'>"
        "<input type='file' name='update' style='margin-bottom:15px;'>"
        "<input type='submit' value='Upload and Update' style='background-color:#007bff;color:white;padding:10px 20px;border:none;border-radius:5px;cursor:pointer;'></form>"
        "<div id='prg' style='margin-top:15px;font-weight:bold;'></div>"

        "<div style='margin-top:30px;'>"
        "<h3 style='margin-bottom:5px;'>Live Sensor Console</h3>"
        "<textarea id='console' style='width:100%; height:250px; background:#1e1e1e; color:#00ff00; font-family:monospace; padding:10px; border-radius:5px;' readonly>Connecting to logs...</textarea>"
        "</div>"
        "</div>"

        "<script>"
        // OTA Upload Logic
        "$('form').submit(function(e){"
        "e.preventDefault();"
        "var form=$('#upload_form')[0];"
        "var data=new FormData(form);"
        "$.ajax({url:'/update',type:'POST',data:data,contentType:false,processData:false,"
        "xhr:function(){"
        "var xhr=new window.XMLHttpRequest();"
        "xhr.upload.addEventListener('progress',function(evt){"
        "if(evt.lengthComputable){"
        "var per=evt.loaded/evt.total;"
        "$('#prg').html('Progress: '+Math.round(per*100)+'%');}"
        "},false);return xhr;},"
        "success:function(d,s){$('#prg').html('Update Success! Rebooting...');},"
        "error:function(a,b,c){$('#prg').html('Update Failed!');}});"
        "});"

        // Live Console Polling Logic (Fetches data every 1 second)
        "setInterval(function(){"
        "  $.get('/logdata', function(data){"
        "    var $console = $('#console');"
        "    if($console.val() !== data) {"
        "       $console.val(data);"
        "       $console.scrollTop($console[0].scrollHeight);"
        "    }"
        "  });"
        "}, 1000);"
        "</script>";

    WebServer server(80);

    // WEB LOGGER BUFFER
    String webLogBuffer = "";

    // Global functions to replace Serial.print so we can see it on the web
    void webPrint(String msg) {
        webLogBuffer += msg;
        // Keep buffer small to prevent ESP32 RAM crashes (keep last 1000 chars)
        if (webLogBuffer.length() > 1500) {
            webLogBuffer = webLogBuffer.substring(webLogBuffer.length() - 1000);
        }
        Serial.print(msg); // Still print to hardware serial just in case
    }

    void webPrintln(String msg) {
        webPrint(msg + "\n");
    }

    void begin() {

        WiFi.begin(ssid, password);
        webPrint("Connecting to WiFi");
        while (WiFi.status() != WL_CONNECTED) {
            delay(500);
            webPrint(".");
        }
        webPrintln("\nWiFi connected. IP: " + WiFi.localIP().toString());

        if (!MDNS.begin(host)) {
            webPrintln("mDNS failed!");
            while (1) delay(1000);
        }

        // Modified route: bypassing login and serving the console immediately
        server.on("/", HTTP_GET, []() {
            server.sendHeader("Connection", "close");
            server.send(200, "text/html", serverIndex);
        });

        server.on("/serverIndex", HTTP_GET, []() {
            server.sendHeader("Connection", "close");
            server.send(200, "text/html", serverIndex);
        });

        // NEW ROUTE: Sends the text logs to the web browser
        server.on("/logdata", HTTP_GET, []() {
            server.send(200, "text/plain", webLogBuffer);
        });

        server.on("/update", HTTP_POST,
                []() {
                    server.sendHeader("Connection", "close");
                    server.send(200, "text/plain", Update.hasError() ? "FAIL" : "OK");
                    ESP.restart();
                },
                []() {
                    HTTPUpload& upload = server.upload();
                    if (upload.status == UPLOAD_FILE_START) {
                        webPrintln("OTA start: " + String(upload.filename.c_str()));
                        if (!Update.begin(UPDATE_SIZE_UNKNOWN)) Update.printError(Serial);
                    } else if (upload.status == UPLOAD_FILE_WRITE) {
                        if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) Update.printError(Serial);
                    } else if (upload.status == UPLOAD_FILE_END) {
                        if (Update.end(true)) webPrintln("OTA OK. Rebooting.");
                    }
                }
        );

        server.begin();

    }

    void update() {
        server.handleClient();
        delay(1);
    }

}
