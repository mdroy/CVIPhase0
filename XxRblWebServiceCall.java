package com.rbl.mit;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URL;

public class XxRblWebServiceCall {

    private static final String USER_AGENT = "Mozilla/5.0";

    public static String request(String url) {
        String resp = null;

        try {
            URL obj = new URL(url);
            Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("dwar2.ratnakarbank.in", 8080));
            HttpURLConnection con = (HttpURLConnection) obj.openConnection(proxy);
            con.setRequestMethod("GET");
            con.setRequestProperty("User-Agent", USER_AGENT);
            int responseCode = con.getResponseCode();

            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
                String inputLine;
                StringBuffer response = new StringBuffer();

                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();

                resp = response.toString();
            } else {
                resp = "GET Response Code :: " + responseCode;
            }
        } catch (IOException e) {
            resp = "Exception " + e.getMessage();
        }
        return resp;
    }
}
