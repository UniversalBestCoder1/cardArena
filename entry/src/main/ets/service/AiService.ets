import http from '@ohos.net.http';

interface AiMessage {
  role: string;
  content: string;
}

interface AiRequest {
  model: string;
  messages: AiMessage[];
  stream: boolean;
}

interface AiChoice {
  message: AiMessage;
}

interface AiResponse {
  choices: AiChoice[];
}

export class AiService {
  // ⚠️ 请将您的 API Key 填在这里
  // 申请地址: https://platform.deepseek.com/
  private static readonly API_KEY = 'sk-ab80c6d344fd4484bbd19168bc9d03c5';
  private static readonly API_URL = 'https://api.deepseek.com/chat/completions';

  static async askAI(userMessage: string): Promise<string> {
    if (AiService.API_KEY.startsWith('sk-xxx')) {
      return '请先在代码 AiService.ets 中配置您的 DeepSeek API Key。';
    }

    try {
      const httpRequest = http.createHttp();
      
      const requestData: AiRequest = {
        model: "deepseek-chat",
        messages: [
          { role: "system", content: "你是一个卡牌游戏(游戏王/万智牌)的专家助手，名字叫'决斗精灵'。请用简短、中二的风格回答玩家的问题。" },
          { role: "user", content: userMessage }
        ],
        stream: false
      };

      const response = await httpRequest.request(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify(requestData),
        readTimeout: 10000,
        connectTimeout: 10000
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as AiResponse;
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content;
        }
        return 'AI 似乎沉默了...';
      } else {
        console.error('[AiService] API Error:', response.responseCode, response.result);
        return `我的魔力暂时枯竭了... (Code: ${response.responseCode})\n${response.result}`;
      }
    } catch (e) {
      console.error('[AiService] Network Error:', JSON.stringify(e));
      return '无法连接到决斗网络 (网络错误)';
    }
  }
}