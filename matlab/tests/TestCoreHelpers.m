classdef TestCoreHelpers < matlab.unittest.TestCase
    methods (Test)
        function configUsesLockedConstants(testCase)
            cfg = grsl_config('data-root', 'output-root');
            testCase.verifyEqual(cfg.wanning.hMax, 18.78, 'AbsTol', 1e-12);
            testCase.verifyEqual(cfg.oahu.hMax, 21.10, 'AbsTol', 1e-12);
            testCase.verifyEqual(cfg.wanning.referenceWaterSurface, -6.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(cfg.wanning.trainingWaterSurface, -7.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(cfg.wanning.referenceWaterSurface - ...
                cfg.wanning.sourceReferenceWaterSurface, 0.5, 'AbsTol', 1e-12);
        end

        function metricsUsePredictionMinusReference(testCase)
            ref = [1; 2; 3];
            pred = [0; 2; 4];
            m = grsl.metrics.calc_metrics(ref, pred);
            testCase.verifyEqual(m.Bias, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(m.RMSE, sqrt(2/3), 'AbsTol', 1e-12);
            testCase.verifyEqual(m.MAE, 2/3, 'AbsTol', 1e-12);
        end

        function binsAreLowerInclusiveUpperExclusive(testCase)
            ref = [0; 1.999; 2; 3.999; 4];
            pred = ref - 1;
            T = grsl.metrics.compute_depth_bins(ref, pred, 0:2:6, 2);
            testCase.verifyEqual(T.N, [2; 2; 1]);
            testCase.verifyEqual(T.Reliable, [true; true; false]);
            testCase.verifyEqual(T.Bias_m(1:2), [-1; -1], 'AbsTol', 1e-12);
            testCase.verifyTrue(isnan(T.Bias_m(3)));
        end

        function depthWeightsArePositiveAndNormalized(testCase)
            y = (1:10)';
            w = grsl.depth.make_depth_weights(y, 9, 4, 4);
            testCase.verifyGreaterThan(w, zeros(size(w)));
            testCase.verifyGreaterThanOrEqual(diff(w), zeros(numel(w)-1, 1));
            testCase.verifyEqual(mean(w), 1, 'AbsTol', 1e-12);
        end

        function candidateGridAndQuantizationAreDeterministic(testCase)
            specs = grsl.wanning.candidate_specs();
            testCase.verifyNumElements(specs, 27);
            q = grsl.quantize.coord([-0.1; 0.01; 0.99; 1.1], 10);
            testCase.verifyEqual(q, [0; 0; 0.9; 1], 'AbsTol', 1e-12);
        end

        function productionFilesContainOneFunctionEach(testCase)
            matlabRoot = fileparts(fileparts(mfilename('fullpath')));
            files = dir(fullfile(matlabRoot, '**', '*.m'));
            files = files(~contains(string({files.folder}), [filesep 'tests']));
            for i = 1:numel(files)
                path = fullfile(files(i).folder, files(i).name);
                content = fileread(path);
                count = numel(regexp(content, '(?m)^function\s', 'match'));
                testCase.verifyLessThanOrEqual(count, 1, ...
                    sprintf('Multiple functions remain in %s.', path));
            end
        end
    end
end
