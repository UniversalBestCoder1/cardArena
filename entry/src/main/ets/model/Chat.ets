export interface ChatMessage {
  id: number;
  sender_id: string;
  sender_name: string;
  sender_role: string;
  receiver_id?: string;
  content: string;
  timestamp: number;
}