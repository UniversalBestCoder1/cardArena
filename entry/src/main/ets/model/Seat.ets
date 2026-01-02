export interface Seat {
  id: string;
  label: string;
  isBooked: boolean;
  type: 'COMMON' | 'VIP';
}