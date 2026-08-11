import { Card } from "@/components/ui/card";

export function EmptySection({ message }: { message: string }) {
  return (
    <Card className="border-dashed border-stone-200 bg-stone-50/70 p-8 text-center text-sm text-ink-faint">
      {message}
    </Card>
  );
}
