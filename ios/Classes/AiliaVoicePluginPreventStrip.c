//
//  AiliaVoicePluginPreventStrip.c
//
//  Created by Kazuki Kyakuno on 2023/07/31.
//

// Dummy link to keep libailia_voice.a from being deleted

extern const char* ailiaVoiceGetErrorDetail(void* net);

void test(void){
    ailiaVoiceGetErrorDetail(0);
}
