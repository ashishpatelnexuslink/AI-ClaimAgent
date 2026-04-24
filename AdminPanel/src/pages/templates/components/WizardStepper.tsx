import { Check } from 'lucide-react';

interface WizardStepperProps {
  steps: string[];
  currentIndex: number;
  furthestReached: number;
  onStepClick?: (index: number) => void;
}

export default function WizardStepper({
  steps,
  currentIndex,
  furthestReached,
  onStepClick,
}: WizardStepperProps) {
  return (
    <ol className="flex items-center w-full">
      {steps.map((label, i) => {
        const isDone = i < currentIndex;
        const isActive = i === currentIndex;
        const canJump = onStepClick && i <= furthestReached;
        return (
          <li key={label} className={`flex items-center ${i < steps.length - 1 ? 'flex-1' : ''}`}>
            <button
              type="button"
              disabled={!canJump}
              onClick={canJump ? () => onStepClick(i) : undefined}
              className={`flex items-center gap-2 ${canJump ? 'cursor-pointer' : 'cursor-default'}`}
            >
              <span
                className={`flex items-center justify-center w-8 h-8 rounded-full text-xs font-semibold transition-colors ${
                  isActive
                    ? 'bg-primary text-white'
                    : isDone
                      ? 'bg-success text-white'
                      : 'bg-gray-200 text-gray-500'
                }`}
              >
                {isDone ? <Check size={14} /> : i + 1}
              </span>
              <span
                className={`text-sm font-medium whitespace-nowrap ${
                  isActive ? 'text-primary' : isDone ? 'text-gray-700' : 'text-gray-400'
                }`}
              >
                {label}
              </span>
            </button>
            {i < steps.length - 1 && (
              <div
                className={`flex-1 h-[2px] mx-4 ${i < currentIndex ? 'bg-success' : 'bg-gray-200'}`}
              />
            )}
          </li>
        );
      })}
    </ol>
  );
}
