function specs = candidate_specs()
% Fixed FCNN candidate grid used by the Wanning tuning workflow.
template = grsl.wanning.make_spec('b4_base', 'bands4', [10 10], ...
    'relu', 0, 1500, 1, 1);
specs = repmat(template, 1, 27);
position = 1;
specs(position) = template;
position = position + 1;
specs(position) = grsl.wanning.make_spec('b6_full_base', 'bands4_xy', ...
    [10 10], 'relu', 0, 1500, 1, 1);
modes = {'bands4_row', 'bands4_col', 'bands4_xy10', ...
    'bands4_xy20', 'bands4_xy40'};
tags = {'row', 'col', 'xy10', 'xy20', 'xy40'};
for i = 1:numel(modes)
    mode = modes{i}; tag = tags{i};
    position = position + 1;
    specs(position) = grsl.wanning.make_spec([tag '_10_base'], mode, ...
        [10 10], 'relu', 0, 1800, 1, 1);
    position = position + 1;
    specs(position) = grsl.wanning.make_spec([tag '_16x8_base'], mode, ...
        [16 8], 'relu', 0, 2000, 1, 1);
    position = position + 1;
    specs(position) = grsl.wanning.make_spec([tag '_10_r2p2'], mode, ...
        [10 10], 'relu', 0, 1800, 2, 2);
    position = position + 1;
    specs(position) = grsl.wanning.make_spec([tag '_10_r4p4'], mode, ...
        [10 10], 'relu', 0, 1800, 4, 4);
    position = position + 1;
    specs(position) = grsl.wanning.make_spec([tag '_16x8_r2p2'], mode, ...
        [16 8], 'relu', 0, 2000, 2, 2);
end
assert(position == numel(specs), 'Wanning candidate grid size changed.');
end
