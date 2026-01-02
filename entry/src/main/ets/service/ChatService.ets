import { MockService } from '../mock/MockService';
import { ChatMessage } from '../model/Chat';

export class ChatService {
  
  static async getChatMessages(): Promise<ChatMessage[]> {
    return MockService.getChatMessages();
  }

  static async sendChatMessage(content: string, receiverId: string = ''): Promise<boolean> {
    return MockService.sendChatMessage(content, receiverId);
  }
}