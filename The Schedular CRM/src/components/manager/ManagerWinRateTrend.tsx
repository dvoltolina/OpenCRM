import {
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { WinRateTrendPoint } from '../../pages/manager-dashboard-utils';

interface ManagerWinRateTrendProps {
  trend: WinRateTrendPoint[];
}

export function ManagerWinRateTrend({ trend }: ManagerWinRateTrendProps) {
  if (!trend.length) {
    return <p>No closed deals in the selected range.</p>;
  }

  return (
    <>
      <div style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={trend}>
            <XAxis
              dataKey="bucketLabel"
              tick={{ fontSize: 11 }}
              interval="preserveStartEnd"
            />
            <YAxis
              domain={[0, 100]}
              tick={{ fontSize: 11 }}
              tickFormatter={(v) => `${v}%`}
            />
            <Tooltip
              formatter={(value: number) => `${value.toFixed(1)}%`}
              labelFormatter={(label) => `Period: ${label}`}
            />
            <Line
              type="monotone"
              dataKey="winRate"
              stroke="#22c55e"
              strokeWidth={2}
              dot={{ r: 3 }}
              activeDot={{ r: 5 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>Period</th>
            <th>Won</th>
            <th>Lost</th>
            <th>Win Rate</th>
          </tr>
        </thead>
        <tbody>
          {trend.map((row) => (
            <tr key={row.bucketLabel}>
              <td>{row.bucketLabel}</td>
              <td>{row.won}</td>
              <td>{row.lost}</td>
              <td>{row.winRate.toFixed(1)}%</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default ManagerWinRateTrend;
