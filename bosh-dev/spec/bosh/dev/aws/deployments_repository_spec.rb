require 'spec_helper'
require 'bosh/dev/aws/deployments_repository'

module Bosh::Dev::Aws
  describe DeploymentsRepository do
    include FakeFS::SpecHelpers

    let(:shell) { instance_double('Bosh::Core::Shell', run: 'FAKE_SHELL_OUTPUT') }

    before do
      Bosh::Core::Shell.stub(new: shell)

      ENV.stub(to_hash: {
        'BOSH_JENKINS_DEPLOYMENTS_REPO' => 'fake_BOSH_JENKINS_DEPLOYMENTS_REPO'
      })
    end

    describe '#path' do
      its(:path) { should eq('/mnt/deployments') }

      context 'when "FAKE_MNT" is set' do
        before do
          ENV.stub(to_hash: {
            'BOSH_JENKINS_DEPLOYMENTS_REPO' => 'fake_BOSH_JENKINS_DEPLOYMENTS_REPO',
            'FAKE_MNT' => '/my/private/idaho'
          })
        end

        its(:path) { should eq('/my/private/idaho/deployments') }
      end

      context 'when path is passed into initialize' do
        subject(:deployments_repository) { DeploymentsRepository.new(path_root: '/some/fake/path') }

        its(:path) { should eq('/some/fake/path/deployments') }
      end
    end

    describe '#clone_or_update!' do
      context 'when the directory does exist' do
        before do
          FileUtils.mkdir_p(subject.path)
        end

        context 'when the directory contains a .git subdirectory' do
          before do
            FileUtils.mkdir_p(File.join(subject.path, '.git'))
          end

          it 'updates the repo at "#path"' do
            shell.should_receive(:run).with('git pull')

            subject.clone_or_update!
          end
        end

        context 'when the directory does not contain a .git subdirectory' do
          it 'clones the repo into "#path"'do
            shell.should_receive(:run).with('git clone fake_BOSH_JENKINS_DEPLOYMENTS_REPO /mnt/deployments')

            subject.clone_or_update!
          end
        end
      end

      context 'when the directory does NOT exist' do
        it 'clones the repo into "#path"'do
          shell.should_receive(:run).with('git clone fake_BOSH_JENKINS_DEPLOYMENTS_REPO /mnt/deployments')

          expect {
            subject.clone_or_update!
          }.to change { Dir.exists?(subject.path) }.from(false).to(true)
        end
      end
    end
  end
end
