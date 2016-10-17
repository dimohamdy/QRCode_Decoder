//
//  QRCodeHandler.swift
//  QRCodeReader.swift
//
//  Created by BinaryBoy on 10/16/16.
//  Copyright © 2016 Yannick Loriot. All rights reserved.
//

import UIKit


class QRCodeHandler {
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    func handleQrcode(value:String) {
        
        let urlRegex = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        //        let array = ["^MATMSG:","^tel:","^smsto:","^geo:","^WIFI:","^BEGIN:VCARD"]
        let array = ["^mailto:","^MATMSG:","^SMTP:","^sms:","^SMSTO:","^mmsto","^mms:","^geo:","^tel:","skype:","^MEBKM:","^bitcoin:","^BEGIN:VCALENDAR:","^BEGIN:VEVENT","^BEGIN:VCARD","^WIFI:","(.*?)"]
        
       outerLoop: for pattern in array{
            let matchesResult =  matches(for: pattern,in: value)
            if matchesResult.count > 0 {
                print(matchesResult)
                switch matchesResult.first! {
                case "mailto:","MATMSG:","SMTP:":
                    let mailEncoding =  MailEncoding()
                    mailEncoding.parse(key: matchesResult.first!,value: value)
                    break outerLoop
                case "sms:","SMSTO:":
                    let smsEncoding =   SMSEncoding()
                    smsEncoding.parse(key: matchesResult.first!,value: value)
                    break outerLoop
                case "mmsto:","mms:":
                    let mmsEncoding = MMSEncoding()
                    mmsEncoding.parse(value: value)
                    break outerLoop
                case "geo:":
                    let geolocationEncoding = GeolocationEncoding()
                    geolocationEncoding.parse(value: value)
                    break outerLoop
                case "tel:":
                    let phone = Phone()
                    phone.parse(value: value)
                    break outerLoop
                case "BEGIN:VCALENDAR:","BEGIN:VEVENT":
                    let eventEncoding = EventEncoding()
                    eventEncoding.parse(value: value)
                    break outerLoop
                case "WIFI:":
                    let wifiEncoding = WifiEncoding()
                    wifiEncoding.parse(value: value)
                    break outerLoop
                case "BEGIN:VCARD":
                    let vcardEncoding = VCardEncoding()
                    vcardEncoding.parse(value: value)
                    break
                default:
                    let matchesResult =  matches(for: urlRegex,in: value)
                    if matchesResult.count > 0{
                        let urlEncoding =  UrlEncoding()
                        urlEncoding.parse(value: value)
                    }else{
                        let txtEncoding =  TxtEncoding()
                        txtEncoding.parse(value: value)
                    }
                    
                    break outerLoop
                }
            }
        }
    }
}

class MailEncoding {
    var subject:String? = nil
    var body:String? = nil
    var mailto:String? = nil
    func parse(key:String,value:String) {
        
        
        
        switch key {
        case "mailto:":
            
            //            $"mailto:{this.mailReceiver}?subject={System.Uri.EscapeDataString(this.subject)}&body={System.Uri.EscapeDataString(this.message)}";
            
            let step1:[String] = value.components(separatedBy: "&")
            subject = step1.first?.components(separatedBy:"=").last
            body = step1.last?.components(separatedBy:"=").last
            
            
            let step3:[String] = value.components(separatedBy: "?")
            let step4:[String] = step3.first!.components(separatedBy: ":")
            mailto = step4.last
            
        case "MATMSG:":
            //        $"MATMSG:TO:{this.mailReceiver};SUB:{EscapeInput(this.subject)};BODY:{EscapeInput(this.message)};;";
            
            let replaced = value.replacingOccurrences(of: "MATMSG:", with: "")
            let step1:[String] = replaced.components(separatedBy: ";")
            
            for value in step1 {
                
                let keyAndValue =   value.components(separatedBy: ":")
                
                switch keyAndValue.first! {
                case "TO":
                    mailto = keyAndValue.last
                case "SUB":
                    subject = keyAndValue.last
                case "BODY":
                    body = keyAndValue.last
                default:
                    break
                }
                
            }
            
        case "SMTP:":
            //        $"SMTP:{this.mailReceiver}:{EscapeInput(this.subject, true)}:{EscapeInput(this.message, true)}";
            let replaced = value.replacingOccurrences(of: "SMTP:", with: "")
            let step1:[String] = replaced.components(separatedBy: ":")
            mailto = step1[0]
            subject = step1[1]
            body = step1[2]
            
        default: break
            
        }
    }
}



class SMSEncoding {
    var number:String? = nil
    var body:String? = nil
    func parse(key:String,value:String) {
        
        switch key {
        case "sms:":
            
            //$"sms:{this.number}?body={System.Uri.EscapeDataString(this.subject)}";
            let replaced = value.replacingOccurrences(of: "sms:", with: "")
            let step1:[String] = replaced.components(separatedBy: "=")
            body = step1.last
            number = step1.first?.components(separatedBy:"?").first
            
            
        case "SMSTO:":
            // $"SMSTO:{this.number}:{this.subject}";
            
            let replaced = value.replacingOccurrences(of: "SMSTO:", with: "")
            let step1:[String] = replaced.components(separatedBy: ":")
            
            number = step1.first
             body  = step1.last
            
        default: break
            
        }
        
        
    }
    
}

class MMSEncoding {
    var number:String? = nil
    var body:String? = nil
    func parse(value:String) {
        
        
        switch value {
        case "mmsto:":
            
            //$"sms:{this.number}?body={System.Uri.EscapeDataString(this.subject)}";
            let replaced = value.replacingOccurrences(of: "sms:", with: "")
            let step1:[String] = replaced.components(separatedBy: "=")
            body = step1.last
            number = step1.first?.components(separatedBy:"?").first
            
            
        case "SMSTO:":
            //$"SMSTO:{this.number}:{this.subject}";
            
            let replaced = value.replacingOccurrences(of: "SMSTO:", with: "")
            let step1:[String] = replaced.components(separatedBy: ":")
            
            body = step1.first
            number = step1.last
            
        default: break
            
        }
        
        
    }
    
}

class GeolocationEncoding {
    
    
    var latitude:String? = nil
    var longitude:String? = nil
    func parse(value:String) {
        
        // $"geo:{this.latitude},{this.longitude}";
        
        let replaced = value.replacingOccurrences(of: "geo:", with: "")
        let step1:[String] = replaced.components(separatedBy: ",")
        latitude = step1.first
        longitude = step1.last
        
        
    }
    
}

class Phone {
    
    
    var phone:String? = nil
    func parse(value:String) {
        
        //   $"geo:{this.latitude},{this.longitude}";
        
        let replaced = value.replacingOccurrences(of: "tel:", with: "")
        phone = replaced
        
    }
    
}


class EventEncoding {
    
    
    
    var subject:String? = nil
    var description:String? = nil
    var location:String? = nil
    var start:String? = nil
    var end:String? = nil
    
    
    
    func parse(value:String) {
        
        
        let step1:[String] = value.components(separatedBy: "\n")
        
        for values in step1{
            let keyAndValue:[String] = values.components(separatedBy: ":")
            
            
            //                var vEvent = $"BEGIN:VEVENT{Environment.NewLine}";
            //                vEvent += $"SUMMARY:{this.subject}{Environment.NewLine}";
            //                vEvent += !string.IsNullOrEmpty(this.description) ? $"DESCRIPTION:{this.description}{Environment.NewLine}" : "";
            //                vEvent += !string.IsNullOrEmpty(this.location) ? $"LOCATION:{this.location}{Environment.NewLine}" : "";
            //                vEvent += $"DTSTART:{this.start}{Environment.NewLine}";
            //                vEvent += $"DTEND:{this.end}{Environment.NewLine}";
            //                vEvent += "END:VEVENT";
            
            
            
            switch keyAndValue.first! {
            case "SUMMARY":
                subject = keyAndValue.last
            case "DESCRIPTION":
                description = keyAndValue.last
            case "LOCATION":
                location = keyAndValue.last
            case "DTSTART":
                start = keyAndValue.last
            case "DTEND":
                end = keyAndValue.last
            default:
                break
            }
            
        }
        
    }
    
}

class VCardEncoding {
    
    
    
    var N:String? = nil
    var FN:String? = nil
    var ORG:String? = nil
    var TITLE:String? = nil
    var tel_Home:String? = nil
    var tel_Work:String? = nil
    var ads_work_PREF:String? = nil
    var label_work_PREF:String? = nil
    
    var ads_home:String? = nil
    var label_home:String? = nil
    
    var EMAIL:String? = nil
    
    var REV:String? = nil
    var GENDER:String? = nil
    var NICKNAME:String? = nil
    var GEO:String? = nil
    var BDAY:String? = nil
    
    
    
    func parse(value:String) {
        
        
        let step1:[String] = value.components(separatedBy: "\n")
        
        for values in step1{
            let keyAndValue:[String] = values.components(separatedBy: ":")
            
            
            //                BEGIN:VCARD
            //                VERSION:2.1
            //                N:;Company Name
            //                FN:Company Name
            //                ORG:Company Name
            //                TEL;WORK;VOICE;PREF:+16045551212
            //                TEL;WORK;FAX:+16045551213
            //                ADR;WORK;POSTAL;PARCEL;DOM;PREF:;;123 main street;vancouver;bc;v0v0v0;canada
            //                EMAIL;INTERNET;PREF:user@example.com
            //                URL;WORK;PREF:http://www.example.com/
            //                NOTE:http://www.example.com/
            //                CATEGORIES:BUSINESS,WORK
            //                UID:A64440FC-6545-11E0-B7A1-3214E0D72085
            //                REV:20110412165200
            //                END:VCARD
            
            
            switch keyAndValue.first! {
            case "N":
                N = keyAndValue.last
            case "FN":
                FN = keyAndValue.last
            case "ORG":
                ORG = keyAndValue.last
            case "TITLE":
                TITLE = keyAndValue.last
            case "TEL;WORK;VOICE":
                tel_Work = keyAndValue.last
            case "TEL;HOME;VOICE":
                tel_Home = keyAndValue.last
            case "ADR;WORK;PREF":
                ads_work_PREF = keyAndValue.last
            case "LABEL;WORK;PREF":
                label_work_PREF = keyAndValue.last
            case "ADR;HOME":
                ads_home = keyAndValue.last
            case "LABEL;HOME":
                label_home = keyAndValue.last
            case "EMAIL":
                EMAIL = keyAndValue.last
            case "REV":
                REV = keyAndValue.last
            case "GENDER":
                GENDER = keyAndValue.last
            case "NICKNAME":
                NICKNAME = keyAndValue.last
            case "GEO":
                GEO = keyAndValue.last
            case "BDAY":
                BDAY = keyAndValue.last
                
            default:
                break
            }
            
        }
        
    }
    
}

class WifiEncoding {
    var authType:String? = nil
    var ssidName:String? = nil
    var password:String? = nil
    var isHidden:String? = nil
    
    func parse(value:String) {
        
        
        //  $"WIFI:T:{this.authenticationMode};S:{this.ssid};P:{this.password};{(this.isHiddenSsid ? "H:true" : string.Empty)};";
        
        let replaced = value.replacingOccurrences(of: "WIFI:T:", with: "")
        let step1:[String] = replaced.components(separatedBy: ";")
        authType = step1.first
        ssidName = step1[1].components(separatedBy:":").last
        password = step1[2].components(separatedBy:":").last
        isHidden = step1[3].components(separatedBy:":").last
        
    }
    
}

class UrlEncoding {
    var url:String? = nil
    
    
    func parse(value:String) {
        
        url = value
        
    }
}

class TxtEncoding {
    var txt:String? = nil
    
    func parse(value:String) {
        
        txt = value
        
    }
}
