type Step = 'upload' | 'confirm' | 'map' | 'preview' | 'import' | 'complete';

interface ImportStepTrackerProps {
  currentStep: Step;
}

const steps = [
  {
    key: 'upload',
    title: 'Upload',
    matches: ['upload'] as Step[],
    completesAfter: ['confirm', 'map', 'preview', 'import', 'complete'] as Step[],
  },
  {
    key: 'review',
    title: 'Review',
    matches: ['confirm', 'map', 'preview'] as Step[],
    completesAfter: ['import', 'complete'] as Step[],
  },
  {
    key: 'import',
    title: 'Import',
    matches: ['import', 'complete'] as Step[],
    completesAfter: ['complete'] as Step[],
  },
] as const;

export function ImportStepTracker({ currentStep }: ImportStepTrackerProps) {
  return (
    <div className="import-step-tracker" aria-label="Import progress">
      {steps.map((step, index) => {
        const isActive = step.matches.includes(currentStep);
        const isComplete = step.completesAfter.includes(currentStep);

        return (
          <div key={step.key} className="import-step-tracker__segment">
            <div
              className={[
                'import-step-tracker__step',
                isActive ? 'is-active' : '',
                isComplete ? 'is-complete' : '',
              ]
                .filter(Boolean)
                .join(' ')}
            >
              <div className="import-step-tracker__number">{index + 1}</div>
              <div className="import-step-tracker__label">{step.title}</div>
            </div>
            {index < steps.length - 1 ? <div className="import-step-tracker__line" aria-hidden="true" /> : null}
          </div>
        );
      })}
    </div>
  );
}
