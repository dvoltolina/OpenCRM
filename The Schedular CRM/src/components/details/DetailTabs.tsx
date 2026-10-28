import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';

export interface DetailTabConfig {
  id: string;
  label: string;
  content: ReactNode;
}

interface DetailTabsProps {
  tabs: DetailTabConfig[];
  defaultTabId?: string;
  onTabChange?: (tabId: string) => void;
}

/**
 * Lightweight tabs wrapper for detail views so we can add contextual panes (e.g., email).
 * Renders as a simple stack when only one tab is provided to avoid extra chrome.
 */
export function DetailTabs({ tabs, defaultTabId, onTabChange }: DetailTabsProps) {
  const visibleTabs = useMemo(() => tabs.filter(Boolean), [tabs]);
  const [activeTab, setActiveTab] = useState<string>(() => {
    if (defaultTabId && visibleTabs.some((tab) => tab.id === defaultTabId)) {
      return defaultTabId;
    }
    return visibleTabs[0]?.id ?? '';
  });

  useEffect(() => {
    if (!visibleTabs.length) {
      return;
    }

    const hasActive = visibleTabs.some((tab) => tab.id === activeTab);
    if (!hasActive) {
      const fallbackId =
        (defaultTabId && visibleTabs.some((tab) => tab.id === defaultTabId) && defaultTabId) ||
        visibleTabs[0].id;
      setActiveTab(fallbackId);
    }
  }, [activeTab, defaultTabId, visibleTabs]);

  if (!visibleTabs.length) {
    return null;
  }

  const showTabs = visibleTabs.length > 1;
  const currentTabContent =
    visibleTabs.find((tab) => tab.id === activeTab)?.content ?? visibleTabs[0].content;

  const handleTabChange = (tabId: string) => {
    setActiveTab(tabId);
    onTabChange?.(tabId);
  };

  return (
    <div className="detail-tabs">
      {showTabs && (
        <div className="detail-tabs__list" role="tablist">
          {visibleTabs.map((tab) => {
            const isActive = tab.id === activeTab;
            return (
              <button
                key={tab.id}
                type="button"
                role="tab"
                className={`detail-tabs__tab ${isActive ? 'detail-tabs__tab--active' : ''}`}
                aria-selected={isActive}
                aria-controls={`detail-tab-panel-${tab.id}`}
                onClick={() => handleTabChange(tab.id)}
              >
                {tab.label}
              </button>
            );
          })}
        </div>
      )}

      <div
        id={`detail-tab-panel-${activeTab}`}
        className="detail-tabs__panel"
        role={showTabs ? 'tabpanel' : undefined}
      >
        {currentTabContent}
      </div>
    </div>
  );
}
